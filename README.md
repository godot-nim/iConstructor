# godot-nim/iConstructor

Combine your badge with the official godot editor icon.

## Basic usage

1. place your-badge.svg(s) in the `materials/` directory.

2. rename the file to `(name of class you want to apply).svg`.

   If the file with the corresponding class name does not exist in `materials/`, iConstructor searches sequentially for a file with the name of its parent.  
   In other words, if you want to apply the material to all icons, create a `Node.svg` file, and if you want to use a different material only for Control-type classes, create another `Control.svg` file.

3. add `<icon/>` tag to the part of your-badge.svg where you want to insert the editor icon.

   iConstructor looks for the `<icon/>` tag and replaces that part with the editor icon elements.

4. run `nim makeicons` to generate icons.

   After execution, icons will be generated in `icons/`.  
   At this time, iConstructor caches a lot of information to speed up the iteration. The official icons downloaded are stored in `.downloads/`, while the classlist file, which determines which icons to download, and the missinglist file, which omits to download icons that could not be downloaded are stored in `.cache/`. If you experience problems with processing not running, try deleting these caches.

## Preview icons

When makeicons is successfully executed, three files will be updated: `preview/main.tscn`, `preview/preview/bootstrap.nim`, and `preview/preview.gdextension`.

1. run `gdextwiz build preview` to build the extension for preview.

   Basically, you only need to execute it for the first time.

2. execute `godot --editor preview/project.godot` to check the icon data.

   The first time it is run, an error occurs because the resource has not been imported into the engine. Reload the project according to the error message.
