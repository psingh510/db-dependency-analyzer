import re

def clean_module_definition(module_definition):
    comment_pattern = r'--[^\n]*'
    comment_pattern_2 = r'\/\*[\s\n\t]*[\w\W\s]*\*\/'
    string_pattern = r"\'([^\']*)\'"
    
    module_definition = module_definition.strip()
    module_definition = re.sub(comment_pattern, ' ', module_definition)
    module_definition = re.sub(comment_pattern_2, ' ', module_definition)
    module_definition = re.sub(string_pattern, ' ', module_definition)
    
    return module_definition
