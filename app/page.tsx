import { redirect } from 'next/navigation';

export default function Home() {
  // Redirigir a vista pública de partidos
  redirect('/partidos');
}
