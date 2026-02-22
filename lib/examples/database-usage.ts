/**
 * EJEMPLOS DE USO - CONEXIÓN MYSQL
 * 
 * Este archivo contiene ejemplos prácticos de cómo usar las conexiones
 * a MySQL en tu aplicación Next.js
 */

// ============================================
// OPCIÓN 1: USAR PRISMA (RECOMENDADO)
// ============================================

import { prisma, executeTransaction } from '@/lib/prisma';

// --------------------------------------------
// Ejemplo 1: SELECT simple
// --------------------------------------------
export async function getTeamById(teamId: string) {
  try {
    const team = await prisma.team.findUnique({
      where: { id: teamId },
      include: {
        user: {
          select: {
            name: true,
            email: true,
          },
        },
      },
    });
    
    return team;
  } catch (error) {
    console.error('Error obteniendo equipo:', error);
    throw new Error('No se pudo obtener el equipo');
  }
}

// --------------------------------------------
// Ejemplo 2: INSERT simple
// --------------------------------------------
export async function createTeam(userId: string, teamName: string) {
  try {
    const team = await prisma.team.create({
      data: {
        name: teamName,
        userId: userId,
      },
    });
    
    return team;
  } catch (error) {
    console.error('Error creando equipo:', error);
    throw new Error('No se pudo crear el equipo');
  }
}

// --------------------------------------------
// Ejemplo 3: UPDATE
// --------------------------------------------
export async function updateTeamStats(
  teamId: string, 
  won: boolean, 
  scored: number, 
  conceded: number
) {
  void scored;
  void conceded;

  try {
    const team = await prisma.team.update({
      where: { id: teamId },
      data: {
        gamesWon: won ? { increment: 1 } : undefined,
        gamesLost: !won ? { increment: 1 } : undefined,
        totalGames: { increment: 1 },
      },
    });
    
    return team;
  } catch (error) {
    console.error('Error actualizando estadísticas:', error);
    throw new Error('No se pudieron actualizar las estadísticas');
  }
}

// --------------------------------------------
// Ejemplo 4: DELETE
// --------------------------------------------
export async function deleteTeam(teamId: string, userId: string) {
  try {
    // Verificar que el equipo pertenece al usuario
    const team = await prisma.team.findUnique({
      where: { id: teamId },
    });
    
    if (!team || team.userId !== userId) {
      throw new Error('No tienes permiso para eliminar este equipo');
    }
    
    await prisma.team.delete({
      where: { id: teamId },
    });
    
    return { success: true };
  } catch (error) {
    console.error('Error eliminando equipo:', error);
    throw error;
  }
}

// --------------------------------------------
// Ejemplo 5: Transacción (operaciones múltiples)
// --------------------------------------------
export async function createMatchWithResult(
  matchData: any,
  resultData: any
) {
  try {
    const result = await executeTransaction(async (tx) => {
      // Crear el partido
      const match = await tx.match.create({
        data: matchData,
      });
      
      // Crear el resultado
      const matchResult = await tx.matchResult.create({
        data: {
          ...resultData,
          matchId: match.id,
        },
      });
      
      // Actualizar solicitud
      await tx.matchRequest.update({
        where: { id: matchData.matchRequestId },
        data: { status: 'matched' },
      });
      
      return { match, matchResult };
    });
    
    return result;
  } catch (error) {
    console.error('Error en transacción:', error);
    throw new Error('No se pudo crear el partido y resultado');
  }
}

// --------------------------------------------
// Ejemplo 6: Queries complejas con relaciones
// --------------------------------------------
export async function getTeamWithMatches(teamId: string) {
  try {
    const team = await prisma.team.findUnique({
      where: { id: teamId },
      include: {
        user: {
          select: {
            name: true,
            email: true,
          },
        },
        matchesAsTeam1: {
          include: {
            team2: true,
            matchResult: true,
          },
          orderBy: {
            createdAt: 'desc',
          },
          take: 10,
        },
        matchesAsTeam2: {
          include: {
            team1: true,
            matchResult: true,
          },
          orderBy: {
            createdAt: 'desc',
          },
          take: 10,
        },
      },
    });
    
    return team;
  } catch (error) {
    console.error('Error obteniendo equipo con partidos:', error);
    throw error;
  }
}

// --------------------------------------------
// Ejemplo 7: Búsqueda y filtrado
// --------------------------------------------
export async function searchActiveRequests(filters: {
  footballType?: string;
  dateFrom?: Date;
  dateTo?: Date;
  excludeUserId?: string;
}) {
  try {
    const requests = await prisma.matchRequest.findMany({
      where: {
        status: 'active',
        footballType: filters.footballType || undefined,
        matchDate: {
          gte: filters.dateFrom,
          lte: filters.dateTo,
        },
        userId: filters.excludeUserId 
          ? { not: filters.excludeUserId }
          : undefined,
      },
      include: {
        team: true,
        user: {
          select: {
            name: true,
            phone: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
    
    return requests;
  } catch (error) {
    console.error('Error buscando solicitudes:', error);
    throw error;
  }
}

// --------------------------------------------
// Ejemplo 8: Paginación
// --------------------------------------------
export async function getTeamsPaginated(page: number = 1, pageSize: number = 20) {
  try {
    const skip = (page - 1) * pageSize;
    
    const [teams, total] = await Promise.all([
      prisma.team.findMany({
        skip,
        take: pageSize,
        orderBy: {
          totalGames: 'desc',
        },
        include: {
          user: {
            select: {
              name: true,
            },
          },
        },
      }),
      prisma.team.count(),
    ]);
    
    return {
      teams,
      pagination: {
        page,
        pageSize,
        total,
        totalPages: Math.ceil(total / pageSize),
      },
    };
  } catch (error) {
    console.error('Error obteniendo equipos paginados:', error);
    throw error;
  }
}

// ============================================
// OPCIÓN 2: QUERIES SQL DIRECTAS (Solo si Prisma no es suficiente)
// ============================================

import { query, queryOne, transaction } from '@/lib/mysql';

// --------------------------------------------
// Ejemplo 9: Query SQL directa (SELECT)
// --------------------------------------------
export async function getTopTeamsRaw(limit: number = 10) {
  try {
    const sql = `
      SELECT 
        t.id,
        t.name,
        t.total_games,
        t.games_won,
        (t.games_won * 3 + t.games_drawn) as points,
        (t.goals_for - t.goals_against) as goal_difference
      FROM teams t
      WHERE t.total_games > 0
      ORDER BY points DESC, goal_difference DESC
      LIMIT ?
    `;
    
    const teams = await query<any[]>(sql, [limit]);
    return teams;
  } catch (error) {
    console.error('Error obteniendo ranking:', error);
    throw error;
  }
}

// --------------------------------------------
// Ejemplo 10: INSERT con SQL directo
// --------------------------------------------
export async function createNotificationRaw(
  userId: string,
  title: string,
  message: string
) {
  try {
    const sql = `
      INSERT INTO notifications (user_id, title, message, type, created_at)
      VALUES (?, ?, ?, 'system', NOW())
    `;
    
    const result = await query(sql, [userId, title, message]);
    return result;
  } catch (error) {
    console.error('Error creando notificación:', error);
    throw error;
  }
}

// --------------------------------------------
// Ejemplo 11: Transacción SQL directa
// --------------------------------------------
export async function transferTeamOwnershipRaw(
  teamId: string,
  newOwnerId: string
) {
  try {
    await transaction(async (conn) => {
      // Actualizar equipo
      await conn.execute(
        'UPDATE teams SET user_id = ? WHERE id = ?',
        [newOwnerId, teamId]
      );
      
      // Registrar en audit log
      await conn.execute(
        'INSERT INTO audit_log (user_id, action, entity_type, entity_id, created_at) VALUES (?, ?, ?, ?, NOW())',
        [newOwnerId, 'team_ownership_transfer', 'team', teamId]
      );
    });
    
    return { success: true };
  } catch (error) {
    console.error('Error en transferencia:', error);
    throw error;
  }
}

// --------------------------------------------
// Ejemplo 12: Query compleja con JOIN
// --------------------------------------------
export async function getMatchHistoryRaw(teamId: string) {
  try {
    const sql = `
      SELECT 
        m.id,
        m.final_date,
        CASE 
          WHEN m.team1_id = ? THEN t2.name
          ELSE t1.name
        END as opponent,
        mr.team1_score,
        mr.team2_score,
        CASE
          WHEN mr.winner_id = ? THEN 'Victoria'
          WHEN mr.winner_id IS NULL THEN 'Empate'
          ELSE 'Derrota'
        END as result
      FROM matches m
      INNER JOIN teams t1 ON m.team1_id = t1.id
      INNER JOIN teams t2 ON m.team2_id = t2.id
      LEFT JOIN match_results mr ON m.id = mr.match_id
      WHERE (m.team1_id = ? OR m.team2_id = ?)
        AND m.status = 'completed'
      ORDER BY m.final_date DESC
      LIMIT 20
    `;
    
    const matches = await query(sql, [teamId, teamId, teamId, teamId]);
    return matches;
  } catch (error) {
    console.error('Error obteniendo historial:', error);
    throw error;
  }
}

// ============================================
// EJEMPLO DE USO EN API ROUTE
// ============================================

/**
 * Archivo: app/api/teams/route.ts
 */
/*
import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';

export async function GET() {
  try {
    // Verificar autenticación
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return NextResponse.json(
        { error: 'No autenticado' },
        { status: 401 }
      );
    }
    
    // Obtener equipos del usuario
    const teams = await prisma.team.findMany({
      where: {
        userId: session.user.id,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
    
    return NextResponse.json(teams);
  } catch (error) {
    console.error('Error en GET /api/teams:', error);
    return NextResponse.json(
      { error: 'Error del servidor' },
      { status: 500 }
    );
  }
}

export async function POST(request: Request) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return NextResponse.json(
        { error: 'No autenticado' },
        { status: 401 }
      );
    }
    
    const { name } = await request.json();
    
    // Validación
    if (!name || name.trim().length === 0) {
      return NextResponse.json(
        { error: 'El nombre es requerido' },
        { status: 400 }
      );
    }
    
    // Crear equipo
    const team = await prisma.team.create({
      data: {
        name: name.trim(),
        userId: session.user.id,
      },
    });
    
    return NextResponse.json(team, { status: 201 });
  } catch (error) {
    console.error('Error en POST /api/teams:', error);
    return NextResponse.json(
      { error: 'Error del servidor' },
      { status: 500 }
    );
  }
}
*/

// ============================================
// EJEMPLO DE USO EN SERVER ACTION
// ============================================

/**
 * Archivo: app/actions/teams.ts
 */
/*
'use server';

import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';
import { revalidatePath } from 'next/cache';

export async function createTeamAction(formData: FormData) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return { error: 'No autenticado' };
    }
    
    const name = formData.get('name') as string;
    
    if (!name || name.trim().length === 0) {
      return { error: 'El nombre es requerido' };
    }
    
    const team = await prisma.team.create({
      data: {
        name: name.trim(),
        userId: session.user.id,
      },
    });
    
    revalidatePath('/dashboard/teams');
    
    return { success: true, team };
  } catch (error) {
    console.error('Error creando equipo:', error);
    return { error: 'Error del servidor' };
  }
}

export async function deleteTeamAction(teamId: string) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return { error: 'No autenticado' };
    }
    
    // Verificar propiedad
    const team = await prisma.team.findUnique({
      where: { id: teamId },
    });
    
    if (!team || team.userId !== session.user.id) {
      return { error: 'No autorizado' };
    }
    
    await prisma.team.delete({
      where: { id: teamId },
    });
    
    revalidatePath('/dashboard/teams');
    
    return { success: true };
  } catch (error) {
    console.error('Error eliminando equipo:', error);
    return { error: 'Error del servidor' };
  }
}
*/
