cd ../../maps/module

FOR /R %%f IN (*.dmm) DO (
  java -jar ../../tools/jmerge/JMerge.jar -clean %%f.backup %%f %%f
)

pause
