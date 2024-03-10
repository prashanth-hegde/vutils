import cli { Command, Flag }
import os
import net.urllib as enc

fn main() {
  mut app := Command {
    name: 'urlencode'
    description: 'provides url encoding for the input parameter'
    required_args: 1
    execute: fn (cmd Command) ! {
      println(enc.query_escape(cmd.args[0]))
    }
  }

  app.setup()
  app.parse(os.args)
}