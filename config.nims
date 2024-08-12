# --define: "api.tag:godot-4.2.2-stable"
--define: "api.tag:master"

task makeicons, "download official kind of node icons and combine with materials/*.svg.":
  selfExec "r makeicons"