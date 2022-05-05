rec {
  makeSpec = contents: builtins.derivation {
    name = "spec.json";
    system = "x86_64-linux";
    preferLocalBuild = true;
    allowSubstitutes = false;
    builder = "/bin/sh";
    args = [ (builtins.toFile "builder.sh" ''
      echo "$contents" > $out
    '') ];
    contents = builtins.toJSON contents;
  };
  jobOfPR = id: info: {
    name = "pr${id}";
    value = makeJob 10
      "PR ${id}: ${info.title}"
      "git+https://github.com/${info.head.repo.full_name}?ref=${info.head.ref}";
  };
  makeJob = priority: description: flake: {
    inherit description flake;
    enabled = 1;
    type = 1;
    hidden = false;
    #checkinterval = 10;
    checkinterval = 0; # check interval is zero because we rely on github webhooks to update jobs
    schedulingshares = priority;
    enableemail = false;
    emailoverride = "";
    keepnr = 1;
  };
  attrsToList = l:
    builtins.attrValues (
      builtins.mapAttrs (name: value: {inherit name value;}) l
    );
  readJson = prs: builtins.fromJSON (builtins.readFile prs);
  makeJobsets = branch: repo: { prs, ... }: {
    jobsets = makeSpec (
      builtins.listToAttrs (map ({name, value}: jobOfPR name value) (attrsToList (readJson prs))) // {
        master = makeJob 100 branch repo;
      }
    );
  };
}
