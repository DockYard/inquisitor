defmodule Inquisitor do
  defmacro __using__(opts) do
    quote do
      @__inquisitor__model__ unquote(opts[:with])
      @__inquisitor__whitelist__ unquote(opts[:whitelist])
      @before_compile Inquisitor
    end
  end

  defmacro __before_compile__(env) do
    model     = Module.get_attribute(env.module, :__inquisitor__model__)
    whitelist = Module.get_attribute(env.module, :__inquisitor__whitelist__)
    fn_name   = :"build_#{name_from_model(model)}_query"

    quote do
      def unquote(fn_name)(params) do
        list =
          params
          |> Map.to_list()
          |> Inquisitor.whitelist_filter(unquote(whitelist))
          |> Inquisitor.preprocess()
        unquote(fn_name)(unquote(model), list)
      end

      def unquote(fn_name)(query, []), do: query
      def unquote(fn_name)(query, [{attr, value}|tail]) do
        query
        |> where([r], field(r, ^String.to_existing_atom(attr)) == ^value)
        |> unquote(fn_name)(tail)
      end
    end
  end

  def preprocess([]), do: []
  def preprocess([{attr, value}|tail]) when value == "true" or value == "false" do
    Ecto.Type.cast(:boolean, value)
    |> elem(1)
    |> (&preprocess([{attr, &1} | tail])).()
  end
  def preprocess([{attr, value}|tail]),
    do: [{attr, value} | preprocess(tail)]

  def whitelist_filter(params, nil), do: params
  def whitelist_filter(params, whitelist) do
    Enum.filter(params, &Enum.member?(whitelist, elem(&1, 0)))
  end

  defp name_from_model(model) do
    model
    |> Code.eval_quoted()
    |> elem(0)
    |> inspect()
    |> String.split(".")
    |> List.last()
    |> Mix.Utils.underscore()
  end
end
