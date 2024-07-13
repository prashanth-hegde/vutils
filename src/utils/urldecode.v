import cli { Command, Flag }
import net.urllib as enc

fn main() {
  mut app := Command {
    name: 'urldecode'
    description: 'provides url decoding for the input parameter'
    required_args: 1
    execute: fn (cmd Command) ! {
    	decoded := enc.query_unescape(cmd.args[0]) or {
     		eprintln('error: $err')
       	return
      }
      println(decoded)
    }
  }

  app.setup()
  app.parse(arguments())
}
