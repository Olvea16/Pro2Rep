﻿using System;
using System.Drawing;
using System.Windows.Forms;
using System.IO.Ports;
using System.Threading;
using System.Text;

namespace SerialTerminalApplication
{
    public partial class Form1 : Form
    {
        string exeFolder = System.IO.Path.GetDirectoryName(Application.ExecutablePath);
        bool Connected = false;
        bool autoConnect = false;
        byte[] readByte = new byte[1];

        public Form1()
        {
            System.IO.StreamWriter logFile = new System.IO.StreamWriter(exeFolder + "/SeriTermLog.txt", true);
            logFile.WriteLine("----------");
            logFile.Close();
            InitializeComponent();
            RefreshPorts();
            UpdateLog("Program started by " + Environment.UserName + ".");
            browseReadTBox.Text = exeFolder + "/ReadData.txt";
            portCBox.Text = "COM5";
            baudRateCBox.Text = "9600";
            ToolTip autoConnectToolTip = new ToolTip();
            autoConnectToolTip.SetToolTip(this.autoConnectCBox, "Auto-Connect: \r\n The program tries to connect repeatedly until succesfully connecting or unchecking this control.");
        }

        private void UpdateStatus(string message)
        {
            if (InvokeRequired) this.Invoke(new Action<string>(UpdateReadFile), new object[] { message });
            else
            {
                statusLabel.Text = message;
                UpdateLog(message);
            }
        }

        private void UpdateReadFile(string message)
        {
            if (InvokeRequired) this.Invoke(new Action<string>(UpdateReadFile), new object[] { message });
            else
            {
                System.IO.StreamWriter readDataFile = new System.IO.StreamWriter(browseReadTBox.Text, true);
                readDataFile.WriteLine("----------" );
                readDataFile.WriteLine(DateTime.Now.ToString("h:mm:ss tt"));
                readDataFile.WriteLine(message);
                readDataFile.WriteLine();
                readDataFile.Close();
            }
        }

        private void UpdateLog(string message)
        {
            try
            {
                System.IO.StreamWriter logFile = new System.IO.StreamWriter(exeFolder + "/SeriTermLog.txt", true);
                logFile.WriteLine(DateTime.Now.ToString("h:mm:ss tt") + ": " + message);
                logFile.Close();
            }
            catch (System.IO.IOException) { }
        }

        private void RefreshPorts()
        {
            portCBox.Items.Clear();
            String[] s = SerialPort.GetPortNames();
            portCBox.Items.AddRange(s);
            UpdateStatus("Refreshed Ports.");
        }

        private void UpdateConnectionPanel(int val)
        {
            switch (val)
            {
                case 1:
                    connectionStatusPanel.BackColor = Color.Red;
                    break;

                case 2:
                    connectionStatusPanel.BackColor = Color.Yellow;
                    break;

                case 3:
                    connectionStatusPanel.BackColor = Color.Green;
                    break;
            }
        }

        private void ReadCheckbox()
        {
            if (InvokeRequired) Invoke(new MethodInvoker(ReadCheckbox));
            else
            {
                if (autoConnectCBox.Checked) autoConnect = true;
                else autoConnect = false;
            }
        }

        private void UpdateReadBox(string message)
        {
            if (InvokeRequired) this.Invoke(new Action<string>(UpdateReadBox), new object[] { message });
            else readTBox.Text += message;
        }

        // Connect bruger den angivne Port og Baud rate til at kalde tryconnect. Den kalder tryconnect for evigt hvis autoconnect er true, derfor skal dette fungere i sit eget thread.
        private void Connect()
        {
            ReadCheckbox();
            if (!autoConnect) TryConnection();
            while (autoConnect && !serialPort.IsOpen)
            {
                ReadCheckbox();
                TryConnection();
            }
            if (serialPort.IsOpen) Invoke(new MethodInvoker(ConnectionEstablished));
            else Invoke(new MethodInvoker(ConnectionLost));
        }

        // TryConnection forsøger at oprette en forbindelse og sender fejlkoder hvis den ikke kan forbinde.
        private void TryConnection()
        {
            try
            {
                serialPort.Encoding = Encoding.UTF8;
                serialPort.Open();
                serialPort.BreakState = false;
                String ConnectionMessage = "";
                foreach (byte b in serialPort.ReadExisting())
                {
                    if (!holdCBox.Checked) ConnectionMessage += Convert.ToChar(b);
                }
                UpdateReadBox(ConnectionMessage + "\r\n");
            }
            catch (System.IO.IOException e)
            {
                if (autoConnect) UpdateStatus("Couldn't connect. Retrying." + e.Message);
                else UpdateStatus("Couldn't connect." + e.Message);
            }
            catch (UnauthorizedAccessException e) { UpdateStatus("Unauthorized access. Couldn't connect." + e.Message); }
        }

        // Thread der a: holder styr på om der stadig er forbindelse og b: hvad der bliver skrevet til PC'en. 
        private void ConnectionThread()
        {
            Thread.Sleep(1000);
            while (serialPort.IsOpen) Thread.Sleep(200);
            ConnectionLost();
        }

        //Opdatering af Status, knapper og indikator til connected-mode.
        private void ConnectionEstablished()
        {
            Connected = true;
            UpdateStatus(portCBox.Text + " has been opened with a baud rate of " + baudRateCBox.Text + ".");
            UpdateConnectionPanel(3);
            RefreshButtons();

            Thread connectionThread = new Thread(new ThreadStart(ConnectionThread)); 
            connectionThread.Start(); //Start thread der holder styr på connection og read data.
        }

        //Opdatering af status og knapper til tab af connected-mode
        private void ConnectionLost()
        {
            if (InvokeRequired) //Hvis metoden ikke bliver kaldt i den samme tråd som UI, skal den invokes i UI metoden.
            {
                try { Invoke(new MethodInvoker(ConnectionLost)); }
                catch (System.ComponentModel.InvalidAsynchronousStateException) { }
            }
            else
            {
                serialPort.Dispose();
                serialPort.Close();
                UpdateStatus("Connection lost. Please try reconnecting.");
                Connected = false;
                connectBtn.Text = "Connect";
                RefreshButtons();
                UpdateConnectionPanel(1);
                UpdateReadBox("\r\n");
            }
            
        }

        // Opdaterer knapper baseret på om der er forbindelse eller ej.
        private void RefreshButtons()
        {
            portCBox.Enabled = !Connected;
            baudRateCBox.Enabled = !Connected;
            autoConnectCBox.Enabled = !Connected;
            refreshBtn.Enabled = !Connected;
            if (Connected)
            {
                connectBtn.Text = "Disconnect";
            }
            else
            {
                connectBtn.Text = "Connect";
            }

            typeCBox.Enabled = Connected;
            commandCBox.Enabled = Connected;
            dataTBox.Enabled = Connected;
            sendAsFileBtn.Enabled = Connected;
            sendBtn.Enabled = Connected;
        }

        private void LoadWriteFile(string addr)
        {
            System.IO.StreamReader writeFile = new System.IO.StreamReader(addr);
            String[] fileList = writeFile.ReadToEnd().Split(';');
            foreach(String line in fileList)
            {
                byte[] bA = new byte[3];
                int i = 0;
                String[] lineList = line.Split(',');
                foreach (String s in lineList)
                {
                    bA[i] = Convert.ToByte(int.Parse(s.Replace("\r\n", "").Remove(0, 2), System.Globalization.NumberStyles.HexNumber));
                    i++;
                }
                WriteByteArray(bA);
            }            
        }

        private void WriteByteArray(byte[] bA)
        {
            int i = 0;
            String[] sentBytes = new String[3];     
            serialPort.Write(bA, 0, 3);
            foreach (byte b in bA)
            {             
                sentBytes[i]= b.ToString("X2");
                i++;
            }
            UpdateStatus("Succesfully sent: (0x" + sentBytes[0] + ", 0x" + sentBytes[1] + ", 0x" + sentBytes[2] + ").");
        }

        private void ReadData()
        {
            int BytesToRead = serialPort.BytesToRead;
            for(int i = 0; i < BytesToRead; i++)
            {
                if (!holdCBox.Checked) UpdateReadBox("0x" + serialPort.ReadByte().ToString("X2") + ", ");
            }
            //foreach (byte b in serialPort.ReadExisting())
            //{
            //    if (!holdCBox.Checked) UpdateReadBox("0x" + b.ToString("X2") + ", ");
            //}
        }

        private void refreshBtn_Click(object sender, EventArgs e)
        {
            RefreshPorts();
        }

        private void connectBtn_Click(object sender, EventArgs e)
        {
            if (!Connected)
            {
                if (!(portCBox.Text == "" || baudRateCBox.Text == ""))
                {
                    UpdateStatus("Connecting, please wait.");
                    UpdateConnectionPanel(2);
                    serialPort.PortName = portCBox.Text;
                    serialPort.BaudRate = Convert.ToInt32(baudRateCBox.Text);                    
                    Thread tryConnectThread = new Thread(new ThreadStart(Connect)); // Her prøver jeg at starte et nyt thread til connection så brugerfladen ikke fryser.
                    tryConnectThread.Start();
                }
                else UpdateStatus("Please select both a valid port and baud rate.");
            }
            else
            {
                UpdateStatus("Disconnecting, please wait.");
                serialPort.DiscardInBuffer();
                serialPort.DiscardOutBuffer();
                serialPort.Close();
            }
            
        }

        private void sendBtn_Click(object sender, EventArgs e)
        {
            byte[] b = new byte[3];
            Int32 dataLength = dataTBox.Text.Length;
            b[0] = Convert.ToByte(int.Parse(typeCBox.Text.Remove(0, 2), System.Globalization.NumberStyles.HexNumber));
            b[1] = Convert.ToByte(int.Parse(commandCBox.Text.Remove(0, 2), System.Globalization.NumberStyles.HexNumber));
            if (dataTBox.Text[dataLength - 1] == '%') b[2] = Convert.ToByte(Convert.ToInt16(dataTBox.Text.Remove(dataLength - 1)));           
            else b[2] = Convert.ToByte(int.Parse(dataTBox.Text.Remove(0, 2), System.Globalization.NumberStyles.HexNumber));

            WriteByteArray(b);
        }

        private void serialPort_DataReceived(object sender, SerialDataReceivedEventArgs e)
        {
            ReadData();    
        }

        private void browseReadBtn_Click(object sender, EventArgs e)
        {
            OpenFileDialog openFileDialog1 = new OpenFileDialog();
            openFileDialog1.InitialDirectory = exeFolder;
            openFileDialog1.Filter = "txt files (*.txt)|*.txt|All files (*.*)|*.*";
            openFileDialog1.FilterIndex = 2;
            openFileDialog1.RestoreDirectory = true;
            if (openFileDialog1.ShowDialog() == DialogResult.OK) browseReadTBox.Text = openFileDialog1.FileName;
        }

        private void exportBtn_Click(object sender, EventArgs e)
        {
            if (!(browseReadTBox.Text == "")) UpdateReadFile(readTBox.Text);
            else UpdateStatus("Please select a file path.");
            UpdateStatus("Exported read data to: (" + browseReadTBox.Text + ")");
        }

        private void clearBtn_Click(object sender, EventArgs e)
        {
            readTBox.Text = "";
            UpdateStatus("Cleared read data.");
        }

        private void browseSendBtn_Click(object sender, EventArgs e)
        {
            OpenFileDialog openFileDialog1 = new OpenFileDialog();
            openFileDialog1.InitialDirectory = exeFolder;
            openFileDialog1.Filter = "txt files (*.txt)|*.txt|All files (*.*)|*.*";
            openFileDialog1.FilterIndex = 2;
            openFileDialog1.RestoreDirectory = true;
            if (openFileDialog1.ShowDialog() == DialogResult.OK) browseSendTBox.Text = openFileDialog1.FileName;
        }

        private void sendAsFileBtn_Click(object sender, EventArgs e)
        {
            if (!(browseSendTBox.Text == "")) LoadWriteFile(browseSendTBox.Text);
            else UpdateStatus("Please select a file path.");
        }

        private void Form1_FormClosing(object sender, FormClosingEventArgs e)
        {
            if (serialPort.IsOpen)
            {
                serialPort.DiscardInBuffer();
                serialPort.DiscardOutBuffer();
                serialPort.Dispose();
                serialPort.Close();
            }
        }

        private void serialPort_PinChanged(object sender, SerialPinChangedEventArgs e)
        {
            ReadData();
        }
    }
}
