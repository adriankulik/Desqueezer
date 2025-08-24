# Desqueezer

**Desqueezer** is a Lightroom plugin that batch-applies an anamorphic desqueeze factor to selected DNG files by modifying their metadata using `exiftool`.

**❗Please note: This plugin irreversibly changes the metadata. Please backup your photos before use.**

---

## ⚙️ Prerequisites

Before running the plugin, make sure the following setup steps are completed:

### 1. Install `exiftool`

This plugin uses `exiftool` to modify DNG metadata.  
Install it via [Homebrew](https://formulae.brew.sh/formula/exiftool):

```bash
brew install exiftool
```

### 2. Make the Bash Script Executable

From the root of the plugin directory, run:

```bash
chmod +x ./scripts/desqueezer.sh
```

### 3. Use DNG Files Only

This plugin only works on DNG files.
If your camera does not shoot in DNG format, export your photos to DNG:

1. Create a subfolder
2. Export the images as DNG
3. Run the plugin on the exported files

### 4. (Optional) Install other required `brew` packages

Run the `brew:install` script located in the `package.json` file. Those scripts are required for keeping the repository neatly formatted and cleanly written.

## 🧩 Installing the Plugin in Lightroom

To install **Desqueezer** in Lightroom Classic:

1. Locate or create your **Lightroom Plugins folder**. This is usually located in:
   - **macOS:** `~/Library/Application Support/Adobe/Lightroom/Modules/`
   - **Windows:** `C:\Users\<YourName>\AppData\Roaming\Adobe\Lightroom\Modules\`
2. Copy the entire `Desqueezer.lrdevplugin` folder (including all its contents) into that `Modules` directory.
3. Open Lightroom Classic.
4. Go to: `File → Plug-in Manager...`
5. Click **"Add"** (or **"Reload Plug-in"** if updating), then navigate to the `Desqueezer.lrdevplugin` folder.

6. Click **Done** when the plugin is successfully loaded.

You should now see **"Desqueezer"** as an option under:

- `Library → Plug-in Extras`
- `File → Plug-in Extras`

> 💡 If you make changes to the plugin code, you can simply reload it from the Plug-in Manager.

## 🚧 Next Steps / Roadmap

- [x] **UI for Squeeze Factor**  
       Allow users to input custom squeeze ratios.  
       _(Currently hardcoded to `1.5x`, suitable for lenses like Blazar Remus and Atlas Mercury.)_

- [x] **Orientation Handling**  
       Add support for both horizontal and vertical images.  
       _(Currently assumes vertical anamorphic, resulting in square 1:1 output.)_

- [x] **Add linting to .sh and .lua files**  
       Unify the code formatting.

- [ ] **Add a README GIF to ilustrate how this plugin works**  
       Show users how to install and use this plugin in a visual manner.

- [ ] **Windows Compatibility**  
       Make the plugin functional on Windows machines using PowerShell or `.bat` alternatives.

## 📄 License

Licensed under the MIT License.
Please retain original author attribution in any distributions or derivatives.

© 2025 Adrian Kulik
