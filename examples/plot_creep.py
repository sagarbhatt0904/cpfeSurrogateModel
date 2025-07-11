import matplotlib.pyplot as plt
import pandas as pd

file = pd.read_csv('example_out.csv')
x_axis_1 = file['time']
y_axis_1 = file['strain']
plt.plot(x_axis_1, y_axis_1, color='k', ls='solid', label='full')



plt.xlabel("Time (hr)")
plt.ylabel("Strain")
plt.gca().ticklabel_format(axis='x', style='sci', scilimits=(0,0))
plt.legend()
# plt.show()	
plt.savefig('creep.png',bbox_inches='tight')
