---
title: A Document
author: Joe Doe
---

# Pandoc-Plot Test Document

This is a sample plot based on <https://matplotlib.org/stable/users/getting_started/#draw-a-first-plot>.

```{.matplotlib directory="/tmp/tests/" format=SVG}
import matplotlib.pyplot as plt
import numpy as np

x = np.linspace(0, 2 * np.pi, 200)
y = np.sin(x)

fig, ax = plt.subplots()
ax.plot(x, y)
```

