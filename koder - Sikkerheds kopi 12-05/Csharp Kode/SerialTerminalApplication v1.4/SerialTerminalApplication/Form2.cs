using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using SerialTerminalApplication.Properties;
using System.IO.Ports;

namespace SerialTerminalApplication
{
    public partial class Form2 : Form
    {
        string exeFolder = System.IO.Path.GetDirectoryName(Application.ExecutablePath);

        public Form2()
        {
            InitializeComponent();

            var sD = Settings.Default;

            writeTimeoutTB.Text = sD["writeTimeout"].ToString();
            readTimeoutTB.Text = sD["readTimeout"].ToString();

            logPathTB.Text = (string)sD["logPath"];
            exportPathTB.Text = (string)sD["exportPath"];

            defaultBaudrateTB.Text = sD["baudRate"].ToString();

            defaultPortCB.Items.Clear();
            String[] s = SerialPort.GetPortNames();
            defaultPortCB.Items.AddRange(s);
            defaultPortCB.Text = (string)sD["portName"];

            enableLogCBox.Checked = (bool)sD["enableLog"];
        }

        private void browseLogPathBtn_Click(object sender, EventArgs e)
        {
            OpenFileDialog oFD = new OpenFileDialog();
            oFD.InitialDirectory = exeFolder;
            oFD.Filter = "txt files (*.txt)|*.txt|All files (*.*)|*.*";
            oFD.FilterIndex = 2;
            oFD.RestoreDirectory = true;
            if (oFD.ShowDialog() == DialogResult.OK) logPathTB.Text = oFD.FileName;
        }

        private void browseExportPathBtn_Click(object sender, EventArgs e)
        {
            OpenFileDialog oFD = new OpenFileDialog();
            oFD.InitialDirectory = exeFolder;
            oFD.Filter = "txt files (*.txt)|*.txt|All files (*.*)|*.*";
            oFD.FilterIndex = 2;
            oFD.RestoreDirectory = true;
            if (oFD.ShowDialog() == DialogResult.OK) exportPathTB.Text = oFD.FileName;
        }

        private void saveBtn_Click(object sender, EventArgs e)
        {
            
            var sD = Settings.Default;

            sD["writeTimeout"] = Convert.ToInt32(writeTimeoutTB.Text);
            sD["readTimeout"] = Convert.ToInt32(readTimeoutTB.Text);

            sD["portName"] = defaultPortCB.Text;
            sD["baudRate"] = Convert.ToInt32(defaultBaudrateTB.Text);

            sD["logPath"] = logPathTB.Text;
            sD["exportPath"] = exportPathTB.Text;

            sD["enableLog"] = enableLogCBox.Checked;

            sD.Save();
            
        }
    }
}

//File dialog til browse-knap

