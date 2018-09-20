required.packages <- c("reshape", "reshape2", "ggplot2", "data.table", "Cairo",
		"snowfall", "gplots", "Rserve", "foreach", "doParallel", "visreg",
		"pROC", "jsonlite", "RUnit");
missing.packages <- function(required) {
	return(required[
		!(required %in% installed.packages()[,"Package"])]);
}
new.packages <- missing.packages(required.packages)
if (length(new.packages)) {
	print("Installing packages...")
	print(new.packages)
	install.packages(new.packages, repos=Sys.getenv("CRAN_MIRROR"));
}

if (length(missing.packages(required.packages))) {
	print("Failed packages...")
	failed.packages <- missing.packages(required.packages)
	print(failed.packages)
	warning('Some packages not installed');
	quit("no");
}
