#%%
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.cm as cm
import matplotlib.colors as colors
import os


#%%
# Colormap setup
cmap = cm.jet
norm = colors.Normalize(vmin=30, vmax=300)  # Adjust vmin/vmax as needed

#%%
# Set Paths
# Get all numeric subdirectories
base_dir = '../creepSim'
folders = sorted([f for f in os.listdir(base_dir) if f.isdigit()], key=lambda x: int(x))

#%%
# Initialize plot
fig, ax = plt.subplots()

for folder in folders:
    csv_path = os.path.join(base_dir, folder, f'{folder}_out.csv')
    load_path = os.path.join(base_dir, folder, 'load.i')

    # Read data
    file = pd.read_csv(csv_path)
    load = float(open(load_path).read().split('=')[1].strip())

    x_axis = file['time']
    y_axis = file['strain']

    plt.plot(x_axis, y_axis, color=cmap(norm(load)), ls='solid')

# Add labels and formatting
ax.set_xlabel("Time (hr)")
ax.set_ylabel("Strain")
ax.ticklabel_format(axis='x', style='sci', scilimits=(0, 0))
ax.set_aspect(1.0/ax.get_data_ratio(), adjustable='box')
# Colorbar setup using ScalarMappable linked to the Axes
sm = plt.cm.ScalarMappable(cmap=cmap, norm=norm)
sm.set_array([])  # Dummy array for compatibility
cbar = fig.colorbar(sm, ax=ax, fraction=0.046, pad=0.04)
cbar.set_label('Load (MPa)')
# plt.show()
plt.tight_layout()
plt.savefig('allCreepCurves.png')
# %%
# Now put the load and creep life  in vectors and plot those
# creepLife=[]
# loads=[]
usable=0
for folder in folders:
    output_path = os.path.join(base_dir, folder, f'{folder}_out.csv')
    load_path = os.path.join(base_dir, folder, 'load.i')

    # Read data
    load = float(open(load_path).read().split('=')[1].strip())
    output_data = pd.read_csv(output_path)
    if (output_data['time'].max()<1e6 and output_data['strain'].max()>0.03 ):
        usable+=1
        plt.plot(load, output_data['time'].max(), marker='o', markerfacecolor='none', linestyle='none', c=cmap(norm(load)))

plt.title(f'Usable Simulations:  {usable}')
plt.xlabel("Load (MPa)")
plt.ylabel("Time to tert (hrs)")
plt.savefig("usable.png")