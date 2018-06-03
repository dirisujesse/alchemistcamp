defmodule MinimalTodo do
  def start do
    input =
      IO.gets("Would you like to create a new .csv? (y/n)\n")
      |> String.trim()
      |> String.downcase()

    if input == "y" do
      create_initial_todo()
      |> get_command()
    else
      load_csv()
    end
  end

  def create_headers() do
    IO.puts(
      ~s{What data should each Todo have?\n} <>
        ~s{Enter field names one by one and an empty line when you're done}
    )

    create_header([])
  end

  def create_header(headers) do
    case IO.gets("Add field: ") |> String.trim() do
      "" -> headers
      header -> create_header([header | headers])
    end
  end

  def create_initial_todo() do
    headers = create_headers()
    name = get_item_name(%{})
    fields = Enum.map(headers, &field_from_user(&1))
    IO.puts(~s{New Todo: "#{name}" added.})

    %{name => Enum.into(fields, %{})}
  end

  def read(filename) do
    case File.read(filename) do
      {:ok, data} ->
        data

      {:error, reason} ->
        IO.puts(~s{Couldn't open file: #{filename}\n})
        IO.puts(~s{#{:file.format_error(reason)}\n})
        start()
    end
  end

  def parse(body) do
    [headers | lines] = String.split(body, ~r{(\r\n|\n|\r)})

    titles = String.split(headers, ",") |> tl()

    parse_lines(titles, lines)
  end

  def parse_lines(titles, lines) do
    Enum.reduce(lines, %{}, fn line, acc ->
      line =
        line
        |> String.split(",")

      # IO.puts(line)

      case line do
        [""] ->
          acc

        [name | fields] ->
          map =
            Enum.zip(titles, fields)
            |> Enum.into(%{})

          Map.merge(acc, %{name => map})
      end
    end)
  end

  def show_todos(data, next_command? \\ true) do
    items = Map.keys(data)
    IO.puts("You have the following Todos:\n")
    Enum.each(items, &IO.puts/1)
    IO.puts("\n")

    if next_command? do
      get_command(data)
    end
  end

  def get_command(data) do
    prompt = """
    Type the first letter of the command you want to run:
    R)ead Todos   A)dd a Todo   D)elete a Todo   L)oad a .csv   S)ave a .csv

    """

    command =
      IO.gets(prompt)
      |> String.trim()
      |> String.downcase()

    case command do
      "r" -> show_todos(data)
      "a" -> add_todo(data)
      "d" -> delete_todo(data)
      "l" -> load_csv()
      "s" -> save_csv(data)
      "q" -> "Goodbye!"
      _ -> get_command(data)
    end
  end

  def add_todo(data) do
    name = get_item_name(data)
    titles = get_fields(data)
    fields = Enum.map(titles, &field_from_user/1) |> Enum.into(%{})

    new_todo = %{name => fields}

    data = Map.merge(data, new_todo)
    get_command(data)
  end

  def get_item_name(data) do
    name = IO.gets("Enter the name of the new Todo:\n") |> String.trim()

    if Map.has_key?(data, name) do
      IO.puts("Todo with that name already exists. Please enter a new name\n")
      get_item_name(data)
    else
      name
    end
  end

  def get_fields(data) do
    data[hd(Map.keys(data))] |> Map.keys()
  end

  def field_from_user(name) do
    field = IO.gets("#{name}: ") |> String.trim()
    {name, field}
  end

  def delete_todo(data) do
    todo = IO.gets("Which Todo would you like to delete?\n") |> String.trim()

    if Map.has_key?(data, todo) do
      IO.puts("OK!\n")
      data = Map.drop(data, [todo])
      IO.puts("Todo deleted: #{todo}\n")
      get_command(data)
    else
      IO.puts("Todo not found\n")
      show_todos(data, false)
      delete_todo(data)
    end
  end

  def load_csv() do
    filename =
      IO.gets("Filename (.csv): ")
      |> String.trim()

    read(filename)
    |> parse()
    |> get_command()
  end

  def prepare_csv(data) do
    headers = ["Item" | get_fields(data)]
    items = Map.keys(data)

    item_rows =
      Enum.map(items, fn item ->
        # data[item] is alsa map, hence we get values of the that map
        [item | Map.values(data[item])]
      end)

    rows = [headers | item_rows]
    row_strings = Enum.map(rows, &Enum.join(&1, ","))

    Enum.join(row_strings, "\n")
  end

  def save_csv(data) do
    filename = IO.gets("Name of the file: ") |> String.trim()
    filedata = prepare_csv(data)

    case File.write(filename, filedata) do
      :ok ->
        IO.puts("CSV saved")

      {:error, reason} ->
        IO.puts("Couldn't save file: #{filename}")
        IO.puts("#{:file.format_error(reason)}\n")
    end

    get_command(data)
  end
end
