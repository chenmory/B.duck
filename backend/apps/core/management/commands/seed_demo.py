from django.core.management.base import BaseCommand

from apps.core.services import ensure_demo_family


class Command(BaseCommand):
    help = "Create demo parent, child, device, settings, stats and legal documents."

    def handle(self, *args, **options):
        parent, child, device = ensure_demo_family()
        self.stdout.write(self.style.SUCCESS(f"Demo parent: {parent.name}"))
        self.stdout.write(self.style.SUCCESS(f"Demo child: {child.nickname}"))
        self.stdout.write(self.style.SUCCESS(f"Demo device: {device.name} / {device.serial_number}"))
