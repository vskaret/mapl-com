import re
from sys import argv

### some method(s) ###

def write_config_to_file(fname, output):
    with open(fname, 'w') as outfile:
        outfile.write("mod GEO-INIT is\n")
        outfile.write("  protecting GEO-DEFINITION .\n")
        outfile.write("  protecting GEO-FUNCS .\n")
        outfile.write("  protecting GEO-PETROLEUM .\n")
        outfile.write("  protecting NAT .\n")
        outfile.write(output)
        outfile.write("\nendm")

#def replace_pattern(text, values_list, pattern_list, output_file, comments=""):
def replace_pattern(text, values_list, pattern_list, comments=""):
    """Replaces parts of the text where it has matched with an element from the pattern list
    with the corresponding element in the values_list. It will first replace the first match,
    with all elements in the first list in values_list, then make a recursive call to create
    all the different possibilities.

    Note that the patterns in pattern list must have two groups (one before the word to be
    replaced and one after)."""

    # need copy of the list because of using pop later (pop will edit the list outside of this scope)
    values_list = values_list.copy()
    pattern_list = pattern_list.copy()

    if len(values_list) != len(pattern_list):
        print("replace_pattern(): lists must be of same length")
        return


    # remove finished pattern
    pattern = pattern_list[0]
    if re.search(pattern, text) is None:
    # all cases for this pattern is finished, so remove it
        pattern_list.pop(0)
        values_list.pop(0)

    # base case (when no more things to replace), write output to file
    if not values_list:
        # oops not so nice maybe (global variables)
        global equation_number, operator_name

        #if equation_number == 0:
            #print("**")
            #print(comments)

        # change operator name
        op_text = "\n\n\n  op " + operator_name + str(equation_number) + " : -> Configuration [ctor] .\n"
        #output_file.write(op_text)

        # add number to the eq name as in eq caseStudy becomes eq caseStudy0
        eq_text = "  eq " + operator_name + str(equation_number) + text + "\n"
        #output_file.write(eq_text+"\n")

        fname = out_file + str(equation_number) + ".maude"
        output = "\n" + comments + op_text + eq_text

        write_config_to_file(fname, output)

        equation_number += 1
        return

    # values_list: something like [['sealing', 'non-sealing'], ['shale', 'non-shale']]
    # pattern_list: something like [filling_pattern, geounit_type_pattern] (regex patterns with two groups)
    values = values_list[0]
    pattern = pattern_list[0]

    for value in values:
        # assumption made for the following geo-unit
        #geo_unit = re.search(pattern,text).group(1).split("\n")[0]
        info = re.search(pattern,text).group(1)
        geo_unit = re.search(geo_unit_pattern, info).group(1)


        # replace the part of pattern which is not in the first group or second group with value
        result = re.sub(pattern, r'\g<1>'+value+r'\g<2>', text, count=1)



        # add assumption comment
        comment = comments + "--- Geo-unit " + geo_unit + " is assumed to be " + value + "\n"

        # replace the rest
        #replace_pattern(result, values_list, pattern_list, output_file, comment)
        replace_pattern(result, values_list, pattern_list, comment)





### start of script ###

# filenames
in_file = "geo-init2.maude"
#out_file = "test-init2.maude"
out_file = "test-init"

# global variables (for writing out to file)
equation_number = 0
operator_name = "caseStudy"

# terminal arguments:
if len(argv) > 1 and argv[1].lower() in ['?', 'h', 'help', '--help', '-h']:
    print("python3 config-gen.py input-file output-file [maude-operator-name]")
    print("If no command line arguments given, default will be:")
    print("input-file: 'geo-init.maude'")
    print("output-file: 'test-init.maude'")
    print("maude-operator-name: 'caseStudy'")
    exit()

# python3 config-gen.py input-file output-file
if len(argv) > 2:
    in_file = argv[1]
    out_file = argv[2]

# python3 config-gen.py input-file output-file [maude-operator-name]
if len(argv) > 3:
    operator_name = argv[3]


# replacement values
fault_filling_values = ["sealing", "non-sealing"]
#traptype_values = ["anticlinal", "faultDependent"]
permeability_values = ["permeable", "non-permeable"]
porosity_values = ["porous", "non-porous"]

# sub patterns
# non-grouped
sandstone = r"<[^>]*?Type: sandstone"
unknown = r"unknown"
# grouped (these parts will be kept during replacement, but can max have 2)
#fault_filling = r"(<.*?Fault.*?Filling: )"
fault_filling = r"(<[^>]*?Fault[^>]*?Filling: )"
end = r"([^>]*?>)"
sandstone_permeability = r"(" + sandstone + r"[^>]*?Permeability: )"
sandstone_porosity = r"(" + sandstone + r"[^>]*?Porosity: )"

# replacement (regex) patterns
# want to replace unknown, so keep the rest (the grouped part in parentheses)
fault_filling_pattern = re.compile(fault_filling + unknown + end, flags=re.DOTALL)
traptype_pattern = re.compile(r"(trapformation\(\d+,)unknown(\))")
permeable_sandstone_pattern = re.compile(sandstone_permeability + unknown + end, flags=re.DOTALL)
porosity_sandstone_pattern = re.compile(sandstone_porosity + unknown + end, flags=re.DOTALL)

equation_pattern = re.compile(r"eq " + operator_name + r"(.*?\.)", re.DOTALL)
geo_unit_pattern = re.compile(r"< (\d+)")

list_of_values = [
    fault_filling_values,
    #permeability_values,
    #porosity_values
]

list_of_patterns = [
    fault_filling_pattern,
    #permeable_sandstone_pattern,
    #porosity_sandstone_pattern
]

# clear output file
#with open(out_file, 'w') as out:
    #out.write("")


#with open(in_file, 'r') as input:
    #with open(out_file, 'a') as out:
        #text = input.read()
        #equation_text = re.findall(equation_pattern, text)

        #configs = re.findall(equation_pattern, text)
        #for config in configs:
            #out.write("mod GEO-INIT is\n")
            #out.write("  protecting GEO-DEFINITION .\n")
            #out.write("  protecting GEO-FUNCS .\n")
            #out.write("  protecting GEO-PETROLEUM .\n")
            #out.write("  protecting NAT .\n")
            #replace_pattern(config, list_of_values, list_of_patterns, out)
            #out.write("\nendm")


with open(in_file, 'r') as input:
    text = input.read()
    equation_text = re.findall(equation_pattern, text)

    configs = re.findall(equation_pattern, text)
    i = 0
    for config in configs:

        # utskrivingen skjer i løvnodene..

        comment = "--- Assumptions made in Python:\n"

        replace_pattern(config, list_of_values, list_of_patterns, comment)

        #with open(out_file + str(i) + ".maude", 'w') as out:
            #out.write("mod GEO-INIT is\n")
            #out.write("  protecting GEO-DEFINITION .\n")
            #out.write("  protecting GEO-FUNCS .\n")
            #out.write("  protecting GEO-PETROLEUM .\n")
            #out.write("  protecting NAT .\n")

            #comment = "--- Assumptions made in Python:\n"

            #replace_pattern(config, list_of_values, list_of_patterns, out, comment)

            #out.write("\nendm")
