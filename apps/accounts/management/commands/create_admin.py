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

        user, created = User.objects.get_or_create(
            email=email,
            defaults={'nome': 'Admin', 'is_staff': True, 'is_superuser': True, 'role': 'autoridade'},
        )
        user.set_password(password)
        user.is_staff = True
        user.is_superuser = True
        user.role = 'autoridade'
        user.save()
        action = 'criado' if created else 'atualizado'
        self.stdout.write(self.style.SUCCESS(f'Admin {email} — {action} com sucesso.'))
