defmodule Inquisitor do
  defmacro __using__([with: model]) do
    quote do
      @__inquisitor__model__ unquote(model)
      @before_compile Inquisitor
    end
  end

  defmacro __before_compile__(env) do
    model = Module.get_attribute(env.module, :__inquisitor__model__)
    name =
      model
      |> Code.eval_quoted()
      |> elem(0)
      |> inspect()
      |> String.split(".")
      |> List.last
      |> Mix.Utils.underscore()

    name =
      "build_#{name}_query"
      |> String.to_atom

    quote do
      defp unquote(name)(params) do
        query = unquote(model)
        list =
          params
          |> Map.delete("format")
          |> Map.to_list()
          |> Inquisitor.preprocess()
        unquote(name)(query, list)
      end

      def unquote(name)(query, []), do: query
      def unquote(name)(query, [{attr, value}|tail]) do
        query
        |> where([r], field(r, ^String.to_existing_atom(attr)) == ^value)
        |> unquote(name)(tail)
      end
    end
  end

  def preprocess([]), do: []
  def preprocess([{attr, value}|tail]) when value == "true" or value == "false" do
    value = Ecto.Type.cast(:boolean, value) |> elem(1)
    preprocess([{attr, value} | tail])
  end
  def preprocess([{attr, value}|tail]),
    do: [{attr, value} | preprocess(tail)]
end
