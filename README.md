# godot-nim/iConstructor

Combine your badge with the official godot editor icon.

## Basic usage

1. place your-badge.svg(s) in the `materials/` directory.

2. add `<icon/>` tag to the part of your-badge.svg where you want to insert the editor icon.

   iConstructor looks for the `<icon/>` tag **recursively** and replaces that part with the editor icon elements.  
   Attributes available for the `<icon/>` tag are summarized at the end of this document.

3. Organize the order of material files

   iConstructor processes material files in alphabetical order. This means that when there are overlapping composites between multiple materials, they will be overwritten with the last material in alphabetical order.

4. run `nim makeicons` to generate icons.

   After execution, icons will be generated in `icons/` (or your specified).  
   At this time, iConstructor caches a lot of information to speed up the iteration. The official icons downloaded are stored in `.downloads/`, while the classlist file, which determines which icons to download, and the missinglist file, which omits to download icons that could not be downloaded are stored in `.cache/`. If you experience problems with processing not running, try deleting these caches.

See inside materials/sample for specific examples. Also, delete the sample directory when actual using.

## Preview icons

When makeicons is successfully executed, three files will be updated: `preview/main.tscn`, `preview/preview/bootstrap.nim`, and `preview/preview.gdextension`.

1. run `gdextwiz build preview` to build the extension for preview.

   Basically, you only need to execute it for the first time.

2. execute `godot --editor preview/project.godot` to check the icon data.

   The first time it is run, an error occurs because the resource has not been imported into the engine. Reload the project according to the error message.

## \<icon /> attributes

| attribute | argument | meaning |
| - | - | - |
| `regex` | regular expression string | Specifies a regular expression to be applied to the material. <br> If specified together with the type attribute, the type attribute is ignored. |
| `type` | Class name (exact match) | Specify the target of material adaptation by class name. The target is the matched class and its child classes. |
| `outdir` | directory path (default: "icons/") | Change the output destination of the composited icons. This allows multiple patterns of icons to be generated at the same time, avoiding overwriting. |