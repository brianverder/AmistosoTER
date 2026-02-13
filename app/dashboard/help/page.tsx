export default function HelpPage() {
  return (
    <div className="max-w-4xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-primary mb-2">💡 Ayuda y Guía de Uso</h1>
        <p className="text-gray-600">
          Aprende a usar Tercer Tiempo para coordinar tus partidos amistosos
        </p>
      </div>

      {/* Guía paso a paso */}
      <div className="space-y-6">
        <div className="card">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 bg-primary text-white rounded-full flex items-center justify-center text-xl font-bold flex-shrink-0">
              1
            </div>
            <div className="flex-1">
              <h2 className="text-xl font-bold text-primary mb-2">⚽ Crea tu Equipo</h2>
              <p className="text-gray-600 mb-3">
                Antes de publicar solicitudes o hacer match, necesitas registrar al menos un equipo. 
                Ve a "Mis Equipos" y crea tu primer equipo con un nombre identificador.
              </p>
              <a href="/dashboard/teams/new" className="btn-primary inline-block text-sm">
                Crear Equipo
              </a>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 bg-primary text-white rounded-full flex items-center justify-center text-xl font-bold flex-shrink-0">
              2
            </div>
            <div className="flex-1">
              <h2 className="text-xl font-bold text-primary mb-2">📢 Publica una Solicitud</h2>
              <p className="text-gray-600 mb-3">
                ¿Buscas rival para un partido? Publica una solicitud con los detalles:
              </p>
              <ul className="list-disc list-inside text-gray-600 space-y-1 mb-3">
                <li>Tipo de fútbol (11, 7, 5, futsal)</li>
                <li>Dirección de la cancha</li>
                <li>Fecha y hora propuesta</li>
                <li>Precio de la cancha</li>
                <li>Notas adicionales</li>
              </ul>
              <p className="text-sm text-gray-500 mb-3">
                💡 Todos los campos son opcionales excepto el equipo
              </p>
              <a href="/dashboard/requests/new" className="btn-primary inline-block text-sm">
                Publicar Solicitud
              </a>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 bg-primary text-white rounded-full flex items-center justify-center text-xl font-bold flex-shrink-0">
              3
            </div>
            <div className="flex-1">
              <h2 className="text-xl font-bold text-primary mb-2">🔍 Busca Partidos</h2>
              <p className="text-gray-600 mb-3">
                Explora las solicitudes publicadas por otros usuarios. En la sección "Solicitudes" 
                verás una pestaña con partidos disponibles. Cuando encuentres uno que te interese:
              </p>
              <ol className="list-decimal list-inside text-gray-600 space-y-1 mb-3">
                <li>Revisa los detalles del partido</li>
                <li>Ve la información de contacto del organizador</li>
                <li>Selecciona uno de tus equipos</li>
                <li>Haz clic en "🤝 Hacer Match"</li>
              </ol>
              <a href="/dashboard/requests" className="btn-primary inline-block text-sm">
                Buscar Partidos
              </a>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 bg-primary text-white rounded-full flex items-center justify-center text-xl font-bold flex-shrink-0">
              4
            </div>
            <div className="flex-1">
              <h2 className="text-xl font-bold text-primary mb-2">🤝 Coordina el Match</h2>
              <p className="text-gray-600 mb-3">
                Una vez que hagas match, ambos equipos podrán ver:
              </p>
              <ul className="list-disc list-inside text-gray-600 space-y-1 mb-3">
                <li>Datos de contacto (email y teléfono)</li>
                <li>Detalles del partido</li>
                <li>Información de los equipos</li>
              </ul>
              <p className="text-gray-600 mb-3">
                Coordina con el rival los detalles finales del partido por email o teléfono.
              </p>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 bg-primary text-white rounded-full flex items-center justify-center text-xl font-bold flex-shrink-0">
              5
            </div>
            <div className="flex-1">
              <h2 className="text-xl font-bold text-primary mb-2">✅ Registra el Resultado</h2>
              <p className="text-gray-600 mb-3">
                Después del partido, registra el resultado en la página del match:
              </p>
              <ul className="list-disc list-inside text-gray-600 space-y-1 mb-3">
                <li>Ingresa los goles de ambos equipos</li>
                <li>El sistema determinará automáticamente el ganador</li>
                <li>Las estadísticas de ambos equipos se actualizarán</li>
              </ul>
              <p className="text-sm text-gray-500">
                💡 Tanto tú como el rival pueden registrar el resultado
              </p>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 bg-primary text-white rounded-full flex items-center justify-center text-xl font-bold flex-shrink-0">
              6
            </div>
            <div className="flex-1">
              <h2 className="text-xl font-bold text-primary mb-2">📊 Revisa Estadísticas</h2>
              <p className="text-gray-600 mb-3">
                En la sección de estadísticas verás:
              </p>
              <ul className="list-disc list-inside text-gray-600 space-y-1 mb-3">
                <li>Resumen global de todos tus equipos</li>
                <li>Partidos ganados, perdidos y empatados</li>
                <li>Porcentaje de efectividad</li>
                <li>Estadísticas individuales por equipo</li>
                <li>Ranking de tu mejor equipo</li>
              </ul>
              <a href="/dashboard/stats" className="btn-primary inline-block text-sm">
                Ver Estadísticas
              </a>
            </div>
          </div>
        </div>
      </div>

      {/* FAQ */}
      <div className="mt-8 card bg-blue-50 border-blue-200">
        <h3 className="text-xl font-bold text-primary mb-4">❓ Preguntas Frecuentes</h3>
        
        <div className="space-y-4">
          <div>
            <h4 className="font-semibold text-primary mb-1">¿Puedo tener varios equipos?</h4>
            <p className="text-sm text-gray-700">
              Sí, puedes crear y gestionar múltiples equipos. Esto es útil si juegas con diferentes 
              grupos de amigos o administras varios equipos.
            </p>
          </div>

          <div>
            <h4 className="font-semibold text-primary mb-1">¿Qué pasa si ya hice match con una solicitud?</h4>
            <p className="text-sm text-gray-700">
              Una vez que se hace match, la solicitud deja de estar disponible para otros usuarios. 
              Ambos equipos pueden ver los datos de contacto para coordinar el partido.
            </p>
          </div>

          <div>
            <h4 className="font-semibold text-primary mb-1">¿Puedo cancelar una solicitud?</h4>
            <p className="text-sm text-gray-700">
              Sí, puedes eliminar solicitudes que aún no tengan match. Una vez que haya match, 
              deberás coordinarlo directamente con el rival.
            </p>
          </div>

          <div>
            <h4 className="font-semibold text-primary mb-1">¿Las estadísticas se actualizan automáticamente?</h4>
            <p className="text-sm text-gray-700">
              Sí, cuando registras un resultado, las estadísticas de ambos equipos (ganados, perdidos, 
              empatados, efectividad) se actualizan automáticamente.
            </p>
          </div>

          <div>
            <h4 className="font-semibold text-primary mb-1">¿Puedo editar el resultado de un partido?</h4>
            <p className="text-sm text-gray-700">
              Por ahora, una vez registrado el resultado no se puede modificar. Asegúrate de 
              ingresar los marcadores correctos antes de guardar.
            </p>
          </div>
        </div>
      </div>

      {/* Consejos */}
      <div className="mt-6 card bg-green-50 border-green-200">
        <h3 className="text-xl font-bold text-primary mb-4">💡 Consejos</h3>
        <ul className="space-y-2 text-sm text-gray-700">
          <li className="flex items-start gap-2">
            <span className="text-accent font-bold mt-0.5">✓</span>
            <span>Completa todos los campos posibles al crear una solicitud para mayor claridad</span>
          </li>
          <li className="flex items-start gap-2">
            <span className="text-accent font-bold mt-0.5">✓</span>
            <span>Agrega tu teléfono en el perfil para facilitar la coordinación</span>
          </li>
          <li className="flex items-start gap-2">
            <span className="text-accent font-bold mt-0.5">✓</span>
            <span>Revisa regularmente la sección de solicitudes disponibles</span>
          </li>
          <li className="flex items-start gap-2">
            <span className="text-accent font-bold mt-0.5">✓</span>
            <span>Coordina los detalles finales con anticipación</span>
          </li>
          <li className="flex items-start gap-2">
            <span className="text-accent font-bold mt-0.5">✓</span>
            <span>Registra los resultados inmediatamente después del partido</span>
          </li>
        </ul>
      </div>
    </div>
  );
}
