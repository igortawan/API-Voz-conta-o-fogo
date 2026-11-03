import os
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model


class Command(BaseCommand):
    help = 'Cria superusuário admin a partir de variáveis de ambiente (idempotente)'

    def handle(self, *args, **options):
        User = get_user_model()
        email = os.environ.get('ADMIN_EMAIL')
        password = os.environ.get('ADMIN_PASSWORD')

        if not email or not password:
            self.stdout.write('ADMIN_EMAIL ou ADMIN_PASSWORD não definidos — pulando.')
            return

        if User.objects.filter(email=email).exists():
            self.stdout.write(f'Admin {email} já existe — pulando.')
            return

        User.objects.create_superuser(email=email, password=password, nome='Admin')
        self.stdout.write(self.style.SUCCESS(f'Superusuário {email} criado com sucesso.'))
