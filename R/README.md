# Reproducible Research Fundamentals 2024 - R

This rep package contains all the necessary code to replicate the findings. To do so please follow the next outlined steps:

1. Open the .Rproj
2. From the .Rproj, run the main.R file. This file calls in all other code files, so don't worry about the others (though read through them, reach out in case of any questions)
3. Before running main
    - If this is the first time, restore the environment with the renv package (lines 3 to 7)
    - Set the path of the data_path (line 33) to where you have stored the data. We expect the data to be organised into (...)/Data/Raw, (...)/Data/Intermediate, (...)/Data/Final. The Raw data folder contains the raw data. The other folders are empty and are populated by the code. However, the code does not create these folders. Please create them before running. 
4. Now run the whole of main.R 
5. The following errors (at least the first time) are expected

```
Warning messages:
1: Labelled data are not supported by the `datasummary_balance()` function. This warning appears once per session. 
2: Please install the `estimatr` package or set `dinm=FALSE` to suppress this warning. 
3: The dot-dot notation (`..y..`) was deprecated in ggplot2 3.4.0.
ℹ Please use `after_stat(y)` instead.
This warning is displayed once every 8 hours.
Call `lifecycle::last_lifecycle_warnings()` to see where this warning was generated. 
4: Using `size` aesthetic for lines was deprecated in ggplot2 3.4.0.
ℹ Please use `linewidth` instead.
This warning is displayed once every 8 hours.
Call `lifecycle::last_lifecycle_warnings()` to see where this warning was generated.
```
