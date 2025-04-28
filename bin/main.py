import importlib
import pkgutil
import sys
from argparse import ArgumentParser
from typing import Tuple, Dict, Any

import loguru
from pyfiglet import Figlet

import xcsp

ALIAS_COMMANDS = {
    "i":"install"
}

#############
# FUNCTIONS #
#############
def discover_and_fill_parsers(package_name, subparser):
    """Découvre les modules d'un package et appelle fill_parser(subparser) pour chacun."""
    package = importlib.import_module(package_name)
    package_path = package.__path__

    # Parcourt les modules du package
    for loader, name, is_pkg in pkgutil.walk_packages(package_path):
        module = importlib.import_module(package_name + '.' + name)

        # Vérifie si le module a une méthode fill_parser
        if hasattr(module, 'fill_parser'):
            # Appelle la méthode fill_parser avec subparser comme argument
            module.fill_parser(subparser)

def parse_arguments() -> Tuple[ArgumentParser, Dict[str, Any]]:
    """
    Parses the command line arguments.

    :return: The parser for the arguments given to Metrics, and the arguments themselves.
    """
    parser = ArgumentParser(prog=xcsp.__name__, description=xcsp.__summary__, add_help=False)

    subparser = parser.add_subparsers(help="The commands recognized by this script.",
                                      dest="command")

    discover_and_fill_parsers("xcsp.commands", subparser)

    # Registering the option used to display the help of the program.
    parser.add_argument('-h', '--help',
                        help='displays the help of XCSP launcher',
                        action='store_true')

    # Registering the option used to display the version of the program.
    parser.add_argument('-v', '--version',
                        help='shows the version of XCSP launcher being executed',
                        action='store_true')

    return parser, vars(parser.parse_args())

def print_header() -> None:
    """
    Displays the header of the program, which shows the name of Metrics with big letters.
    """
    figlet = Figlet(font='slant')
    print(figlet.renderText('XCSP'))


def display_help(parser: ArgumentParser) -> None:
    """
    Displays the help of this script.
    """
    print_header()
    parser.print_help()


def version() -> None:
    """
    Displays the current version of XCSP.
    """
    print_header()
    print('XCSP version', xcsp.__version__)
    print('Copyright (c)', xcsp.__copyright__)
    print('This program is free software: you can redistribute it and/or modify')
    print('it under the terms of the GNU Lesser General Public License.')

################
# MAIN PROGRAM #
################
if __name__ == '__main__':
    # Parsing the command line arguments.
    argument_parser, args = parse_arguments()

    # If the help is asked, we display it and exit.
    if args['help']:
        display_help(argument_parser)
        sys.exit()

    # If the version is asked, we display it and exit.
    if args['version']:
        version()
        sys.exit()

    # Executing the specified Metrics command.
    command = args['command']
    if command == 'help' or command is None:
        display_help(argument_parser)
    elif command == 'version':
        version()
    else:
        try:
            if command in ALIAS_COMMANDS:
                command = ALIAS_COMMANDS[command]
            module = importlib.import_module("xcsp.commands." + command.replace("-", "_"))
            if hasattr(module, 'manage_command'):
                module.manage_command(args)
        except TypeError as e:
            loguru.logger.error(f"Command '{command}' not found.")
            loguru.logger.error(e)