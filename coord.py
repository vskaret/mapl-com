import subprocess
import re

### some methods ###

def list_to_string(list):
    """Takes a list and returns it as a string.

    ['help', 'me'] becomes '[help,me]'"""

    return_value = "["

    for member in list:
        return_value += str(member) + ","

    # remove last comma
    return_value = return_value[0:-1] + "]"
    return return_value

# TODO: how to do search?
def run_maude(configuration, filename, command="rew"):
    """Runs maude and returns the output configuration as a string.

    filenames is a list of filenames. """

    print(configuration)

    # regex to match with the maude configuration from the maude output
    config_regex = re.compile("result .*?: (.*)")

    # pipe for communication with process
    pipe = subprocess.PIPE

    """
    args = [
        "maude", "-no-banner", "-no-wrap", "prolog_message_generation.maude"
    ]
    """

    args = [
        "maude", "-no-banner", "-no-wrap", filename
    ]

    print(command + " " + configuration + " .")

    maude_proc = subprocess.Popen(args, stdout=pipe, stdin=pipe, universal_newlines=True)

    out = maude_proc.communicate(input=command + " " + configuration + " .")
    maude_proc.terminate()

    print(maude_proc.stdout)
    print(out[0])

    config_match = re.search(config_regex, out[0])
    config = config_match.group(1)

    return config

def get_queries(maude_config):
    """Takes a maude configuration as a string and returns all of the prolog queries in
    a list."""

    # regex to find all queries for prolog :
    # it matches with anything on the form queryInside(something(something))
    # where something(something) is what's saved when regex searching
    query_regex = re.compile("queryInside\((.*?\(.*?\))\)")
    query_matches = re.findall(query_regex, config)

    #print(query_matches)

    #for a in query_matches:
        #print(a)

    return query_matches

def run_prolog(queries):
    """Runs prolog and returns the results as a list of strings.

    It's assumed that the prolog program returns its result so that the
    predicates are separated by #."""

    # pipe for communication with process
    pipe = subprocess.PIPE

    cmd_args = [
        "swipl",
        "-s", "pythoninteraction.pl", # obs: the filename might change
        "-g", "handle_queries_test(" + queries + ")",
        "-t", "halt"
    ]

    prolog_proc = subprocess.run(cmd_args, stdout=pipe, universal_newlines=True)

    #print(prolog_proc.stdout)

    result_list = prolog_proc.stdout.split("#")
    #for term in result_list:
        #print(term)

    return result_list

def remove_queries(configuration):
    """Takes in a config all terms of the type queryInside(...)"""
    temp = configuration

    output = re.sub("queryInside\(.*?\(.*?\)\)\s*", "", temp)

    return output


### start of script ###

# run maude (rewrite) with the initial configuration and store the configuration as a string
config = run_maude("init", "prolog_message_generation.maude")
#config = run_maude("init", ["family.maude", "prolog_message_generation.maude"])

# get prolog queries from the configuration
queries_for_prolog = get_queries(config)

# while there are queries for prolog from maude, keep on running
while queries_for_prolog:

    # run prolog and get a list with the new data
    prolog_terms = run_prolog(list_to_string(queries_for_prolog))

    # remove any old queries from the configuration
    config_with_queries_removed = remove_queries(config)

    # add the terms from prolog to the configuration
    for term in prolog_terms:
        config_with_queries_removed += " " + term

    # run maude with the new configuration
    config = run_maude(config_with_queries_removed, "prolog_message_generation.maude")

    # check if there are any queries for prolog
    queries_for_prolog = get_queries(config)
