defmodule DesafioCliTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "SET com sintaxe errada" do
    output = capture_io(fn ->
      store = %KV{}
      DesafioCli.process_command(store, "SET x")
    end)

    assert output == "ERR 'SET <chave> <valor> - Syntax error'\n"
  end

  test "comando não reconhecido TRY" do
    output = capture_io(fn ->
      store = %KV{}
      DesafioCli.process_command(store, "TRY")
    end)

    assert output == "Command not found, TRY\n"
  end

  test "SET com dois valores válidos" do
    output = capture_io(fn ->
      store = %KV{}
      store = DesafioCli.process_command(store, "SET teste 1")
      DesafioCli.process_command(store, "SET teste 2")
    end)

    assert output == "FALSE 1\nTRUE 2\n"
  end

  test "BEGIN, SET e GET dentro de transação" do
    output = capture_io(fn ->
      store = %KV{}
      store = DesafioCli.process_command(store, "BEGIN")
      store = DesafioCli.process_command(store, "SET teste 1")
      DesafioCli.process_command(store, "GET teste")
    end)

    assert output == "1\nFALSE 1\n1\n"
  end

  test "COMMIT aplica transação e GET retorna valor" do
    output = capture_io(fn ->
      store = %KV{}
      store = DesafioCli.process_command(store, "BEGIN")
      store = DesafioCli.process_command(store, "SET teste 1")
      store = DesafioCli.process_command(store, "COMMIT")
      DesafioCli.process_command(store, "GET teste")
    end)

    assert output == "1\nFALSE 1\nCOMMIT\n0\n1\n"
  end

  test "ROLLBACK descarta transação e GET retorna NIL" do
    output = capture_io(fn ->
      store = %KV{}
      store = DesafioCli.process_command(store, "BEGIN")
      store = DesafioCli.process_command(store, "SET teste 1")
      store = DesafioCli.process_command(store, "ROLLBACK")
      DesafioCli.process_command(store, "GET teste")
    end)

    assert output == "1\nFALSE 1\nROLLBACK\n0\nNIL\n"
  end
end
