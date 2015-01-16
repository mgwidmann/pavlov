defmodule Pavlov.Utils.Memoize do
  @moduledoc false
  alias Pavlov.Utils.Memoize.ResultTable

  defmacro defmem(header, do: body) do
    { name, _meta, vars } = header

    quote do
      def unquote(header) do
        case ResultTable.get(unquote(name), unquote(vars)) do
          { :hit, result } -> result
            :miss ->
              result = unquote(body)
              ResultTable.put(unquote(name), unquote(vars), result)
              result
        end
      end
    end
  end

  def flush do
    ResultTable.flush
  end

  # gen_server keeping results for function calls
  defmodule ResultTable do
    @moduledoc false
    use GenServer

    def start_link do
      GenServer.start_link(__MODULE__, HashDict.new, name: :result_table)
    end

    def handle_call({ :get, fun, args }, _sender, dict) do
      if Dict.has_key?(dict, { fun, args }) do
        { :reply, { :hit, dict[{ fun, args }] }, dict }
      else
        { :reply, :miss, dict }
      end
    end
    def handle_call({ :flush }, _sender, dict) do
      { :reply, :hit, Dict.drop(dict, Dict.keys(dict)) }
    end

    def handle_cast({ :put, fun, args, result }, dict) do
      { :noreply, Dict.put(dict, { fun, args }, result) }
    end

    def get(fun, args),         do: GenServer.call(:result_table, { :get, fun, args })
    def put(fun, args, result), do: GenServer.cast(:result_table, { :put, fun, args, result })
    def flush, do: GenServer.call(:result_table, { :flush })
  end
end
