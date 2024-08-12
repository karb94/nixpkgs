{
  buildPythonPackage,
  pythonOlder,
  cmake,
  numpy,
  scipy,
  hatchling,
  stdenv,
  xgboost,
}:

buildPythonPackage {
  pname = "xgboost";
  format = "pyproject";
  inherit (xgboost) version src meta;

  disabled = pythonOlder "3.8";

  nativeBuildInputs = [
    cmake
    hatchling
  ];
  buildInputs = [ xgboost ];
  propagatedBuildInputs = [
    numpy
    scipy
  ];

  pythonRemoveDeps = [
    "nvidia-nccl-cu12"
  ];

  # Override existing logic for locating libxgboost.so which is not appropriate for Nix
  prePatch =
    let
      libPath = "${xgboost}/lib/libxgboost${stdenv.hostPlatform.extensions.sharedLibrary}";
    in
    ''
      ln -s ${xgboost}/lib lib
      echo 'XGBOOST LIBRARY PATH: ${libPath}'
    '';

  dontUseCmakeConfigure = true;

  postPatch = ''
    cd python-package
  '';

  postInstall =
    let
      libPath = "${xgboost}/lib/libxgboost${stdenv.hostPlatform.extensions.sharedLibrary}";
    in
    ''
      rm $out/lib/python3.12/site-packages/xgboost/lib/libxgboost.so
      ln -s "${libPath}" $out/lib/python3.12/site-packages/xgboost/lib/libxgboost.so
    '';

  # test setup tries to download test data with no option to disable
  # (removing sklearn from nativeCheckInputs causes all previously enabled tests to be skipped)
  # and are extremely cpu intensive anyway
  doCheck = false;

  pythonImportsCheck = [ "xgboost" ];

  __darwinAllowLocalNetworking = true;
}
