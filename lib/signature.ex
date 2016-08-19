# Application cli mount point
defmodule Signature do
  use Application
  alias Signature.{Item, Ftp, Html, Image, Processor, PathAgent}

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    :inets.start
    File.mkdir(".temp")

    children = [
      worker(
        PathAgent, [[]]
      )
    ]

    opts = [strategy: :one_for_one, name: Signature.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def stop(app) do
    :inets.stop
    File.rm_rf(".temp")
    :application.stop(app)
  end

  def main(args) do
    args |> parse_args |> process
  end


  defp parse_args(args) do
    {options, _, _} = OptionParser.parse(args,
      switches: [
        csv:   :string,
        email: :string,
        help:  :boolean,
        gen:   :boolean
      ],
      aliases: [g: :gen]
    )
    case options do
      [help: true] ->
        :help
      [email: email] ->
        {:ok, pid} = :inets.start(:ftpc, host: PathAgent.get.ftp_host)
        {pid, email}
      [csv: csv] ->
        {:ok, pid} = :inets.start(:ftpc, host: PathAgent.get.ftp_host)
        {{pid, csv}, :auto}
      [gen: true] ->
        :csv_gen
      _ ->
      :help
    end
  end

  defp process(:help) do
    IO.puts """
      Usage:
      ./signature --email [employee email address]
      ./signature --csv [path to csv file]

      Options:
      --help Show this help message
      -g Generates sample csv file

      Description:
      Generates, uploads and emails asignature image's for statiagov employees
    """
  end

  defp process(:csv_gen) do
    file = File.open!("employees.csv", [:write])
    [
      %{
        "email" => "",
        "name"  => "",
        "title" => "",
        "adres" => "",
        "tel"   => "",
        "mob"   => ""
      }
    ]
    |> CSV.encode(headers: ["email", "name", "title", "adres", "tel", "mob"])
    |> Enum.each(&IO.write(file, &1))
  end

  defp process({{pid, csv}, :auto}) do
    File.stream!(csv)
    |> Stream.drop(1)
    |> CSV.decode(headers: ["email", "name", "title", "adres", "tel", "mob"])
    |> Enum.map(&row_to_item/1)
    |> Enum.map(&Processor.start(pid, &1))

    Signature.stop(self())
  end

  defp process({pid, email}) do
    item = prompt(email)

    case Vex.valid? item do
      true ->
        Processor.start(pid, item)
        Signature.stop(self())
      _    -> print_errors(item)
    end
  end

  defp prompt(email) do
    name  = IO.gets("Name: ") |> trim
    title = IO.gets("Title: ") |> trim
    adres = IO.gets("Adres: ") |> trim
    tel   = IO.gets("Tel (optional): ") |> trim
    mob   = IO.gets("Mob (optional): ") |> trim
    IO.puts "\n"
    Item.new(%{email: email, name: name, title: title,
      adres: adres, tel: tel, mob: mob})
  end

  defp trim(string) do
    case String.trim(string) do
      "" -> nil
      value -> value
    end
  end

  defp print_errors(item) do
    IO.puts """
      Encountered errors:
    """
    Vex.errors(item) |> Enum.each(fn({_, field, _, message}) ->
      IO.puts "#{to_string(field) |> String.capitalize} #{message}"
    end)
  end

  defp row_to_item(row) do
    item = Item.new %{email: row["email"], name: row["name"], title: row["title"],
             adres: row["adres"], tel: row["adres"], mob: row["mob"]}
    case Vex.valid? item  do
      true -> item
      _    -> raise "Some exception"
    end
  end
end

# Pipeline Processor
defmodule Signature.Processor do
  alias Signature.{Html, Image, Ftp, Mail, Mailer}

  def start(pid, item) do
    with  html        <- Html.image(item),
          {:ok, path} <- Image.convert({item, html}),
          {:ok, link} <- Ftp.upload(pid, path),
          :ok         <- send_mail({item, link}) do
          IO.puts """
                Operation complete successfully
          """
    else
      {:error, message} -> IO.inspect message
    end
  end

  defp send_mail(tuple) do
    Mail.instructions(tuple)
    |> Mailer.deliver_now

    :ok
  end
end

# Ftp service
 defmodule Signature.Ftp do
  alias Signature.PathAgent

  def upload(pid, path) do
    with {:ok, _dir} <- login(pid),
         :ok         <- change_directory(pid) do
         send_file(pid, path)
    else
      {:error, message} -> IO.inspect message
    end
  end

  defp login(pid) do
    :ftp.user(pid, PathAgent.get.ftp_user, PathAgent.get.ftp_login)
    :ftp.pwd(pid)
  end

  defp change_directory(pid), do: :ftp.cd(pid, PathAgent.get.ftp_sig_location)

  defp send_file(pid, path) do
     :ftp.type(pid, :binary)
     :ftp.lcd(pid, working_dir(path))
     case :ftp.send(pid, file_name(path)) do
       :ok -> {:ok, link_to_file(path)}
       {:error, message} -> {:error, message}
     end
  end

  defp link_to_file(file) do
    str = to_string PathAgent.get.ftp_host
    host = str
    |> String.slice(4, String.length(str))
    "http://#{host}/#{file_name(file)}"
  end

  defp working_dir(file), do: String.to_charlist Path.dirname(file)
  defp file_name(file),  do: String.to_charlist Path.basename(file)
end

# Html generater
defmodule Signature.Html do
  require EEx

  @root_dir File.cwd!

  def image(item) do
    css = Path.expand("priv/style.css", @root_dir)
    render_html(signature: item, css: css)
  end

  EEx.function_from_file(:def, :render_html,
    Path.expand("priv/layout.html", @root_dir),
    [:assigns],
    trim: true
  )
end

# Html to image converter
defmodule Signature.Image do
  @temp_dir ".temp"

  def convert({item, html}, extension \\ :jpg) do
    generate_temp_file
    |> write_temp_html_file(html)
    |> convert_to_image(item, extension)
  end

  def generate_temp_file do
    temp_html = "#{@temp_dir}/#{:rand.uniform(1_000_000_000)}.html"
    {:ok, file} = File.open(temp_html, [:write, :utf8])
    {temp_html, file}
  end

  defp write_temp_html_file({temp_html, file}, html) do
    IO.write(file, html)
    temp_html
  end

  defp convert_to_image(temp_html, item, extension) do
    temp_image = "#{@temp_dir}/#{image_name(item)}.#{extension}"
    executable = Signature.PathAgent.get.wkhtml_path
    case Porcelain.shell("#{executable} #{temp_html} #{temp_image}") do
      %Porcelain.Result{err: nil, out: "", status: 0} -> {:ok, temp_image}
      _ -> raise "Error"
    end
  end

  defp image_name(item) do
    [first | _rem] = String.split(item.email, "@")
    first
  end
end

# Defination of signature in terms of struct
defmodule Signature.Item do
  defstruct name: nil,
            title: nil,
            adres: nil,
            tel: nil,
            email: nil,
            mob: nil

  use Vex.Struct

  validates :name,  presence: true
  validates :title, presence: true
  validates :adres, presence: true
  validates :email, presence: true, format: ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/

  def new(values), do: %__MODULE__{} |> Map.merge(values)
end

# Mailer service
defmodule Signature.Mailer do
  use Bamboo.Mailer, otp_app: :signature
end


# Mail defination
defmodule Signature.Mail do
  import Bamboo.Email

  def instructions({item, link}) do
    new_email
    |> to(item.email)
    |> from("it.noreply@statiagov.com")
    |> subject("Signature Instructions")
    |> html_body("""

      Hey, #{item.name} \n

      Please use the following linked image for your signature: <a href =#{link}>signature</a> \n

     \n
     \n

     IT Department Bot

    """)
  end
end

# State Object
defmodule Signature.PathAgent do
  defstruct wkhtml_path: nil,
            ftp_user: nil,
            ftp_login: nil,
            ftp_host: nil,
            ftp_sig_location: nil


  @name __MODULE__

  def start_link(path_options) do
    Agent.start_link(__MODULE__, :init_opts, [path_options], name: @name)
  end

  def init_opts(path_from_options) do
    options = [
      wkhtml_path: System.find_executable("wkhtmltoimage"),
      ftp_user: String.to_charlist(System.get_env("STATIAGOVERNMENT_FTP_USER")),
      ftp_login: String.to_charlist(System.get_env("STATIAGOVERNMENT_FTP_LOGIN")),
      ftp_host: String.to_charlist(System.get_env("STATIAGOVERNMENT_FTP_HOST")),
      ftp_sig_location: String.to_charlist(System.get_env("STATIAGOVERNMENT_FTP_SIG_LOC"))
    ]
    ++ path_from_options

    if Keyword.fetch!(options, :wkhtml_path) == nil do
      raise "path to wkhtmltoimage is neither found on path nor given as wkhtml_path option. Can't continue."
    end

    Map.merge %__MODULE__{}, Enum.into(options, %{})
  end

  def stop do
    Agent.stop @name
  end

  def get do
    Agent.get(@name, fn(data) -> data end)
  end
end
