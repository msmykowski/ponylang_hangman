use "collections"
use "net"

actor Main
  new create(env: Env) =>
    let host = try env.args(1)? else "" end
    let port = try env.args(2)? else "3000" end
    try
      TCPListener(env.root as AmbientAuth,
        recover Server(Game) end, host, port)
    end

class Server is TCPListenNotify
  let _game: Game

  new create(game: Game) =>
    _game = game

  fun ref connected(listen: TCPListener ref): Connection iso^ =>
    Connection(_game)

  fun ref not_listening(listen: TCPListener ref) =>
    None

primitive Connected

class Connection is TCPConnectionNotify
  let _game: Game
  var _status: (None | Connected) = None

  new iso create(game: Game) =>
    _game = game

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] iso,
    times: USize)
    : Bool
  =>
    match _status
    | None =>
      _game.add_connection(conn)
      _status = Connected
    end

    let letter: String val = String.from_iso_array(consume data).>strip()
    _game.guess_letter(letter)
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    None

actor Game
  let connections: Array[TCPConnection] = []
  let word: String = "abc"
  let guesses: Set[String] = guesses.create()


  be add_connection(conn: TCPConnection) =>
    connections.push(conn)

  be guess_letter(guess: String) =>
    guesses.set(guess)
    let contains = word.contains(guess)
    if contains then
      for connection in connections.values() do
        connection.write(word)
      end
    end
