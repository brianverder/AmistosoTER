/**
 * ============================================================
 * DB — Capa Unificada de Acceso a Base de Datos (MySQL)
 * ============================================================
 *
 * Exporta:
 *  - `db`      → PrismaClient singleton (ORM, uso recomendado)
 *  - `pool`    → mysql2 Pool  (queries raw cuando Prisma no alcanza)
 *  - Helpers:
 *      checkDb()           → verifica conexión
 *      withTransaction()   → transacción Prisma
 *      rawQuery()          → query SQL preparado con mysql2
 *      rawQueryOne()       → primer resultado de un rawQuery
 *      rawTransaction()    → transacción raw con mysql2
 *
 * Uso recomendado:
 * ```ts
 * import { db } from '@/lib/db';
 * const users = await db.user.findMany();
 * ```
 *
 * Para queries complejas:
 * ```ts
 * import { rawQuery } from '@/lib/db';
 * const rows = await rawQuery('SELECT * FROM users WHERE email = ?', [email]);
 * ```
 */

export { prisma as db, executeTransaction as withTransaction, checkDatabaseConnection as checkDb } from './prisma';
export { getPool as pool, query as rawQuery, queryOne as rawQueryOne, transaction as rawTransaction } from './mysql';


// ============================================================
// HELPERS DE MÁS ALTO NIVEL
// ============================================================

import { prisma } from './prisma';
import { getPool } from './mysql';
import type { Prisma } from '@prisma/client';

// ---- ESTADÍSTICAS DE LA DB -----

export async function getDbStats() {
  try {
    const stats = await prisma.$queryRaw<Array<{
      TABLE_NAME: string;
      TABLE_ROWS: bigint;
      DATA_LENGTH: bigint;
      INDEX_LENGTH: bigint;
    }>>`
      SELECT TABLE_NAME, TABLE_ROWS, DATA_LENGTH, INDEX_LENGTH
      FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE()
      ORDER BY DATA_LENGTH DESC
    `;

    return stats.map(s => ({
      table: s.TABLE_NAME,
      rows: Number(s.TABLE_ROWS),
      dataMB: +(Number(s.DATA_LENGTH) / 1_048_576).toFixed(2),
      indexMB: +(Number(s.INDEX_LENGTH) / 1_048_576).toFixed(2),
    }));
  } catch {
    return [];
  }
}

// ---- CONTEOS RÁPIDOS -----

export async function getGlobalCounts() {
  const [userCount, teamCount, requestCount, matchCount] = await Promise.all([
    prisma.user.count({ where: { active: true } }),
    prisma.team.count({ where: { active: true } }),
    prisma.matchRequest.count({ where: { status: 'active' } }),
    prisma.match.count({ where: { status: { in: ['pending', 'confirmed', 'completed'] } } }),
  ]);

  return { userCount, teamCount, requestCount, matchCount };
}

// ---- RECALCULAR ESTADÍSTICAS DE UN EQUIPO -----

export async function recalcTeamStats(teamId: string) {
  const results = await prisma.matchResult.findMany({
    where: {
      match: {
        OR: [{ team1Id: teamId }, { team2Id: teamId }],
        status: 'completed',
      },
    },
    include: {
      match: { select: { team1Id: true, team2Id: true } },
    },
  });

  let won = 0, lost = 0, drawn = 0, goalsFor = 0, goalsAgainst = 0;

  for (const r of results) {
    const isTeam1 = r.match.team1Id === teamId;
    const myScore = isTeam1 ? r.team1Score : r.team2Score;
    const theirScore = isTeam1 ? r.team2Score : r.team1Score;

    goalsFor += myScore;
    goalsAgainst += theirScore;

    if (r.winnerId === teamId) won++;
    else if (r.winnerId === null) drawn++;
    else lost++;
  }

  const totalGames = won + lost + drawn;
  const points = won * 3 + drawn;

  await prisma.team.update({
    where: { id: teamId },
    data: { gamesWon: won, gamesLost: lost, gamesDrawn: drawn, totalGames, goalsFor, goalsAgainst, points },
  });

  return { teamId, won, lost, drawn, totalGames, goalsFor, goalsAgainst, points };
}

// ---- RECALCULAR RANKING (season) -----

export async function recalcRanking(options: {
  season: string;
  footballType?: string | null;
  country?: string | null;
}) {
  const { season, footballType = null, country = null } = options;

  const where: Prisma.TeamWhereInput = { active: true };
  if (country) where.country = country;
  if (footballType) where.footballType = footballType;

  const teams = await prisma.team.findMany({
    where,
    select: {
      id: true,
      userId: true,
      gamesWon: true,
      gamesLost: true,
      gamesDrawn: true,
      totalGames: true,
      goalsFor: true,
      goalsAgainst: true,
      points: true,
    },
    orderBy: [
      { points: 'desc' },
      { gamesWon: 'desc' },
      { goalsFor: 'desc' },
    ],
  });

  const ops = teams.map((t, idx) =>
    prisma.ranking.upsert({
      where: {
        teamId_season_footballType_country: {
          teamId: t.id,
          season,
          footballType: footballType ?? '',
          country: country ?? '',
        },
      },
      create: {
        teamId: t.id,
        userId: t.userId,
        season,
        footballType,
        country,
        position: idx + 1,
        points: t.points,
        gamesPlayed: t.totalGames,
        gamesWon: t.gamesWon,
        gamesLost: t.gamesLost,
        gamesDrawn: t.gamesDrawn,
        goalsFor: t.goalsFor,
        goalsAgainst: t.goalsAgainst,
        goalDiff: t.goalsFor - t.goalsAgainst,
      },
      update: {
        userId: t.userId,
        position: idx + 1,
        points: t.points,
        gamesPlayed: t.totalGames,
        gamesWon: t.gamesWon,
        gamesLost: t.gamesLost,
        gamesDrawn: t.gamesDrawn,
        goalsFor: t.goalsFor,
        goalsAgainst: t.goalsAgainst,
        goalDiff: t.goalsFor - t.goalsAgainst,
      },
    })
  );

  await prisma.$transaction(ops);
  return teams.length;
}

// ---- VERIFICAR CONEXIÓN CON RETRY -----

export async function waitForDb(retries = 5, delayMs = 2000): Promise<boolean> {
  for (let i = 0; i < retries; i++) {
    try {
      await prisma.$queryRaw`SELECT 1`;
      console.log('✅ Conexión a MySQL establecida');
      return true;
    } catch (err) {
      console.warn(`⚠️  MySQL no disponible (intento ${i + 1}/${retries}), reintentando en ${delayMs}ms...`);
      await new Promise(r => setTimeout(r, delayMs));
    }
  }
  console.error('❌ No se pudo conectar a MySQL después de varios intentos');
  return false;
}
