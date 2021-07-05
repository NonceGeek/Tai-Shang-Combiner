defmodule TaiShangWeb.ParserLive do
  use TaiShangWeb, :live_view
  alias TaiShang.Parser
  alias Utils.StructTranslator
  @impl true
  def mount(_params, _session, socket) do
    parsers_based_on_addr = Parser.get_by_type("based_on_addr")
    parsers_based_on_token_id = Parser.get_by_type("based_on_token_id")
    IO.puts(inspect(parsers_based_on_token_id))

    {:ok,
     socket
     |> assign(parsers_based_on_addr: parsers_based_on_addr)
     |> assign(parsers_based_on_token: parsers_based_on_token_id)
     |> assign(erc721_addr: "0x962c0940d72E7Db6c9a5F81f1cA87D8DB2B82A23")
     |> assign(evidence_addr: "0xB942FA2273C7Bce69833e891BDdFd7212d2dA415")}
  end

  @impl true
  def handle_event("parse", params, %{assigns: assigns} = socket) do
    parser = assigns.parser_selected
    # erc721_addr = assigns.erc721_addr
    params_atomed = StructTranslator.to_atom_struct(params)

    url =
      case parser.type do
        "based_on_token_id" ->
          "#{parser.url}/?"
          |> Kernel.<>("erc721_addr=#{params_atomed.erc721_addr}")
          |> Kernel.<>("&token_id=#{params_atomed.token_id}")
          |> Kernel.<>("&evidence_addr=#{params_atomed.evidence_addr}")

        "based_on_addr" ->
          "#{parser.url}/?"
          |> Kernel.<>("erc721_addr=#{params_atomed.erc721_addr}")
          |> Kernel.<>("&addr=#{params_atomed.owner_addr}")
          |> Kernel.<>("&evidence_addr=#{params_atomed.evidence_addr}")
      end

    {:noreply, redirect(socket, external: url)}
  end

  def handle_event(key_raw, _params, socket) do
    [key, id] = key_raw_to_key_formatted(key_raw)
    do_handle_event(key, id, socket)
  end

  def do_handle_event("select_parser", id, socket) do
    parser = Parser.get_by_id(id)

    {:noreply,
     socket
     |> assign(parser_selected: parser)}
  end

  def key_raw_to_key_formatted(key_raw) do
    [key, id] = String.split(key_raw, "#")
    [key, String.to_integer(id)]
  end
end
