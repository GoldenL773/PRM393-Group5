import os
import re
from pathlib import Path

lib_dir = Path('PRM393-Group5/goldfit_frontend/lib').resolve()

# Regex to match relative imports
import_pattern = re.compile(r"""import\s+['"]([^'"]+)['"](.*);""")

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    new_content = ""
    lines = content.split('\n')
    changed = False

    for line in lines:
        match = import_pattern.search(line)
        if match:
            import_path = match.group(1)
            rest = match.group(2)

            # Skip package and dart imports
            if import_path.startswith('package:') or import_path.startswith('dart:'):
                new_content += line + '\n'
                continue
            
            # It's a relative import. Resolve it based on current file's directory
            current_dir = filepath.parent
            resolved_path = (current_dir / import_path).resolve()
            
            # Check if resolved path is within lib directory
            try:
                rel_to_lib = resolved_path.relative_to(lib_dir)
            except ValueError:
                # Not inside lib (e.g. tests or external), ignore
                new_content += line + '\n'
                continue
            
            # Now rel_to_lib is something like "shared/models/outfit.dart"
            # Instead of changing it to package:goldfit_frontend/..., let's check if the file exists.
            if resolved_path.exists():
                # We can choose to keep relative, but fix it, OR convert to package:.
                # Let's just convert all internal relative imports to package:goldfit_frontend/
                new_import = f"import 'package:goldfit_frontend/{rel_to_lib.as_posix()}'{rest};"
                new_content += new_import + '\n'
                changed = True
            else:
                # The file DOES NOT EXIST at the old location! This means it was moved.
                # Let's search the entire lib directory for a file with the same name.
                filename = resolved_path.name
                matches = list(lib_dir.rglob(filename))
                
                if len(matches) == 1:
                    new_rel = matches[0].relative_to(lib_dir)
                    new_import = f"import 'package:goldfit_frontend/{new_rel.as_posix()}'{rest};"
                    new_content += new_import + '\n'
                    changed = True
                elif len(matches) > 1:
                    print(f"Warning: Multiple matches for {filename} in {filepath}. Matches: {matches}")
                    new_content += line + '\n'
                else:
                    print(f"Warning: Could not find {filename} imported in {filepath}!")
                    new_content += line + '\n'
        else:
            new_content += line + '\n'
            
    if changed:
        with open(filepath, 'w', encoding='utf-8') as f:
            # removing trailing extra newline
            f.write(new_content[:-1] if new_content.endswith('\n') else new_content)

for p in lib_dir.rglob('*.dart'):
    process_file(p)

print("Imports updated!")
