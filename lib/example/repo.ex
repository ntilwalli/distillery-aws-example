defmodule Example.Repo do
  use Ecto.Repo, otp_app: :distillery_example

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    opts =
      opts
      |> Keyword.put(:url, System.get_env("DATABASE_URL") || Keyword.get(opts, :url))
      |> Keyword.put(:hostname, System.get_env("DATABASE_HOST") ||  Keyword.get(opts, :hostname))

    {:ok, opts}
  end
end
