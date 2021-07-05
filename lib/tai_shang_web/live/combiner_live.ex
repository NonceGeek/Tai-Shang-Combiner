defmodule TaiShangWeb.CombinerLive do
  use TaiShangWeb, :live_view

  @impl true

  @combiner_addr "0xE07D758AC318A84CCdf5E50eb79A2487C90B798B"
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(combiner_addr: @combiner_addr)
      |> assign(erc721_addr: "0x962c0940d72E7Db6c9a5F81f1cA87D8DB2B82A23")
      |> assign(evidence_addr: "0xB942FA2273C7Bce69833e891BDdFd7212d2dA415")
  }
  end

  @impl true
  def handle_event(_key, _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

end
