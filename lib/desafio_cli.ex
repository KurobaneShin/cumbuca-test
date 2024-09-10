defmodule DesafioCli do
  @moduledoc """
  Ponto de entrada para a CLI.
  """

  @doc """
  A função main recebe os argumentos passados na linha de
  comando como lista de strings e executa a CLI.
  """
  def main(_args) do
    kv = %KV{}
   loop(kv)
  end

  def loop(store) do
    IO.puts("Enter your commands")
    raw = IO.gets("> ")
   newStore= process_command(store,raw)
   loop(newStore)
  end

  def process_command(store,raw) do
    trimmedRaw = String.trim(raw)
    case trimmedRaw do
      "BEGIN" ->
        {newStore, message} = KV.begin_transaction(store)
        IO.puts(message)
        newStore
      "ROLLBACK"->
        {newStore, rollback_message} = KV.rollback(store)
        IO.puts(rollback_message)
        newStore
      "COMMIT"->
        {newStore,msg} = KV.commit(store)
        IO.puts(msg)
        newStore
        _ ->
          process_multiple_commands(raw,store)
    end
  end

  defp process_multiple_commands(raw,store) do
 args = Regex.scan(~r/"((?:\\.|[^\\"])*)"|\S+/, raw)
          |> Enum.map(fn
            [_, quoted] -> String.replace(quoted, ~r/\\"/, "\"")  # Remover o escape das aspas
            [unquoted] -> unquoted  # Partes sem aspas
          end)
    [command | rest ] = args
    case command do
      "SET" ->
        set_command(rest,store)
      "GET" ->
        get_command(rest,store)
      _ ->
        IO.puts("Command not found, #{command}")
        store
    end
  end

  def set_command(params,store) when length(params) == 2 do
   [key,val] = params
   {newStore, message} = KV.set(store,key,String.trim(val))
   IO.puts(message)
   newStore
  end

  def set_command(_,store) do
     IO.puts("ERR 'SET <chave> <valor> - Syntax error'")
     store
  end
  def get_command(params,store) do
      [key] = params
      res = KV.get(store,String.trim(key))
      IO.puts(res || "NIL")
      store
  end
end
