@noninteractive
Feature: Command Line Interface non interactive commands

  Scenario: show usage with --help
  When I run `rubyripper_cli --help`
  Then it should pass with exactly:
  """
  Usage: rubyripper_cli [options]
    -V, --version        Show current version of rubyripper.
    -f, --file <FILE>    Load configuration settings from file <FILE>.
    -v, --verbose        Display verbose output.
    -c, --configure      Change configuration settings.
    -d, --defaults       Skip questions and rip the disc.
        --testdisc <CD>  Provide a directory to stub disc queries.
    -B, --batch          Exit after the disc is done ripping.
    -h, --help           Show this usage statement.

  """

  Scenario: show usage with -h
  When I run `rubyripper_cli -h`
  Then it should pass with exactly:
  """
  Usage: rubyripper_cli [options]
    -V, --version        Show current version of rubyripper.
    -f, --file <FILE>    Load configuration settings from file <FILE>.
    -v, --verbose        Display verbose output.
    -c, --configure      Change configuration settings.
    -d, --defaults       Skip questions and rip the disc.
        --testdisc <CD>  Provide a directory to stub disc queries.
    -B, --batch          Exit after the disc is done ripping.
    -h, --help           Show this usage statement.

  """

  Scenario: show version number with -V
  When I run `rubyripper_cli -V`
  Then it should pass with exactly:
  """
  Rubyripper version 0.7.0a1

  """

  Scenario: show version number with --version
  When I run `rubyripper_cli --version`
  Then it should pass with exactly:
  """
  Rubyripper version 0.7.0a1

  """