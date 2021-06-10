defmodule TaiShang.Repo do
  use Ecto.Repo,
    otp_app: :tai_shang,
    adapter: Ecto.Adapters.Postgres
end
