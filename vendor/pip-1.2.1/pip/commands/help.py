from pip.basecommand import (Command, command_dict,
                             load_all_commands, SUCCESS,
                             ERROR)
from pip.exceptions import CommandError
from pip.baseparser import parser


class HelpCommand(Command):
    name = 'help'
    usage = '%prog'
    summary = 'Show available commands'

    def run(self, options, args):
        load_all_commands()
        if args:
            ## FIXME: handle errors better here
            command = args[0]
            if command not in command_dict:
                raise CommandError('No command with the name: %s' % command)
            command = command_dict[command]
            command.parser.print_help()
            return SUCCESS
        parser.print_help()
        print('\nCommands available:')
        commands = list(set(command_dict.values()))
        commands.sort(key=lambda x: x.name)
        for command in commands:
            if command.hidden:
                continue
            print('  %s: %s' % (command.name, command.summary))
        return SUCCESS

HelpCommand()
