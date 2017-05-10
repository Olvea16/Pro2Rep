using System;
using System.Drawing;
using System.Windows.Forms;
using System.IO.Ports;
using System.Threading;

namespace SerialTerminalApplication
{
    public partial class Form1 : Form
    {
        string exeFolder = System.IO.Path.GetDirectoryName(Application.ExecutablePath);
        bool Connected = false;
        byte[] readByte = new byte[1];

        public Form1()
        {
            System.IO.StreamWriter file = new System.IO.StreamWriter(exeFolder + "/SeriTermLog.txt", true);
            file.WriteLine("----------");
            file.Close();
            InitializeComponent();
            RefreshPorts();
            UpdateLog("Program started.");
        }

        private void UpdateStatus(string message)
        {
            statusLabel.Text = message;
            UpdateLog(message);
        }

        private void UpdateLog(string message)
        {
            System.IO.StreamWriter file = new System.IO.StreamWriter(exeFolder + "/SeriTermLog.txt", true);
            file.WriteLine(DateTime.Now.ToString("h:mm:ss tt") + ": " + message);
            file.Close();
        }

        private void RefreshPorts()
        {
            UpdateStatus("Refreshed Ports.");
            portCBox.Items.Clear();
            String[] ports = SerialPort.GetPortNames();
            portCBox.Items.AddRange(ports);
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

        private void UpdateReadBox(string message)
        {
            if (InvokeRequired)
            {
                this.Invoke(new Action<string>(UpdateReadBox), new object[] { message });
            }
            else
            {
                readTBox.Text += message + Environment.NewLine;
            }
        }

        private void Connect()
        {
            serialPort.PortName = portCBox.Text;
            serialPort.BaudRate = Convert.ToInt32(baudRateCBox.Text);
            if (!autoConnectCBox.Checked) TryConnection();
            while (autoConnectCBox.Checked && !serialPort.IsOpen)
            {
                TryConnection();
            }
            
        }

        private void TryConnection()
        {
            try
            {
                serialPort.Open();
            }
            catch (System.IO.IOException)
            {
                if (autoConnectCBox.Checked)
                {
                    UpdateStatus("Couldn't connect. Retrying.");
                }
                else
                {
                    UpdateStatus("Couldn't connect.");
                }
            }
            catch (UnauthorizedAccessException)
            {
                UpdateStatus("Unauthorized access. Couldn't connect.");
            }
        }

        // Thread der a: holder styr på om der stadig er forbindelse og b: hvad der bliver skrevet til PC'en. 
        private void ConnectionThread()
        {
            //serialPort.ReadTimeout = 500;
            while (serialPort.IsOpen)
            {
                //try
                //{
                //    serialPort.Read(readByte, 0, 3);
                //    if (!(readByte.Length > 0))
                //    {
                //        UpdateReadBox(readByte.ToString());
                //        Array.Clear(readByte, 0, readByte.Length);
                //    }

                //}
                //catch (TimeoutException) { }
                //catch (System.IO.IOException) { }
            }
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
                Invoke(new MethodInvoker(ConnectionLost));
            }
            else
            {
                UpdateStatus("Connection lost. Please try reconnecting.");
                Connected = false;
                connectBtn.Text = "Connect";
                RefreshButtons();
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
            exportBtn.Enabled = Connected;
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
                    Thread tryConnectThread = new Thread(new ThreadStart(Connect)); // HEr prøver jeg at starte et nyt thread til connection så brugerfladen ikke fryser.
                    tryConnectThread.Start();
                    ConnectionEstablished();
                }
                else
                {
                    UpdateStatus("Please select both a valid port and baud rate.");
                }
            }
            else
            {
                UpdateStatus("Disconnecting, please wait.");
                serialPort.Close();
            }
            
        }

        private void sendBtn_Click(object sender, EventArgs e)
        {
            byte[] b = new byte[3]; 
            b[0] = Convert.ToByte(int.Parse(typeCBox.Text.Remove(0, 2), System.Globalization.NumberStyles.HexNumber));
            b[1] = Convert.ToByte(int.Parse(commandCBox.Text.Remove(0, 2), System.Globalization.NumberStyles.HexNumber));
            b[2] = Convert.ToByte(int.Parse(dataTBox.Text.Remove(0, 2), System.Globalization.NumberStyles.HexNumber));
            serialPort.Write(b, 1, 1);
            UpdateStatus("Succesfully sent: " + typeCBox.Text + " - " + commandCBox.Text + " - " + dataTBox.Text);
        }

        private void serialPort_DataReceived(object sender, SerialDataReceivedEventArgs e)
        {
            serialPort.Read(readByte, 0, 1);
            UpdateReadBox(BitConverter.ToString(readByte));
            Array.Clear(readByte, 0, readByte.Length);
        }
    }
}
