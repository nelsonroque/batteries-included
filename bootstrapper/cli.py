import subprocess
import typer
import questionary

app = typer.Typer()

STACKS = [
    "vite",
    "nextjs",
    "nextjs-api-client",
    "auth-supabase",
    "api-client-openapi",
]

@app.command()
def bootstrap(
    stack: str = typer.Option(None, help="vite|nextjs|nextjs-api-client|auth-supabase|api-client-openapi"),
    app_name: str = typer.Option(None, help="Project name"),
    pm: str = typer.Option(None, help="Package manager (npm|pnpm)"),
    openapi: str = typer.Option(None, help="OpenAPI URL or path"),
):
    """Bootstrap a new project interactively or with flags."""

    # Ask interactively if flags missing
    if not stack:
        stack = questionary.select(
            "Choose stack:",
            choices=STACKS
        ).ask()

    if not app_name:
        app_name = questionary.text("Enter app name:", default="my-app").ask()

    if not pm:
        pm = questionary.select(
            "Package manager:",
            choices=["npm", "pnpm"]
        ).ask()

    if stack in ["nextjs-api-client", "api-client-openapi"] and not openapi:
        openapi = questionary.text("OpenAPI URL or path (blank to skip):").ask()

    # Map stacks to scripts
    script_map = {
        "vite": "bootstrap_vite_tailwind_shadcn.sh",
        "nextjs": "bootstrap_nextjs_tailwind_shadcn.sh",
        "nextjs-api-client": "bootstrap_nextjs_api_client.sh",
        "auth-supabase": "bootstrap_auth_supabase.sh",
        "api-client-openapi": "bootstrap_api_client_openapi.sh",
    }
    script = script_map[stack]

    args = [app_name, pm] + ([openapi] if "api-client" in stack else [])

    typer.echo(f"▶ Running ./scripts/{script} {' '.join(args)}")
    subprocess.run(["./scripts/" + script] + args, check=True)

if __name__ == "__main__":
    app()
