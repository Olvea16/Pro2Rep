namespace SerialTerminalApplication
{
    partial class Form1
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.components = new System.ComponentModel.Container();
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(Form1));
            this.refreshBtn = new System.Windows.Forms.Button();
            this.portCBox = new System.Windows.Forms.ComboBox();
            this.baudRateCBox = new System.Windows.Forms.ComboBox();
            this.commandCBox = new System.Windows.Forms.ComboBox();
            this.typeCBox = new System.Windows.Forms.ComboBox();
            this.sendDataGBox = new System.Windows.Forms.GroupBox();
            this.sendAsFileBtn = new System.Windows.Forms.Button();
            this.browseSendBtn = new System.Windows.Forms.Button();
            this.browseSendTBox = new System.Windows.Forms.TextBox();
            this.dataLabel = new System.Windows.Forms.Label();
            this.commandLabel = new System.Windows.Forms.Label();
            this.typeLabel = new System.Windows.Forms.Label();
            this.sendBtn = new System.Windows.Forms.Button();
            this.dataTBox = new System.Windows.Forms.TextBox();
            this.readDataGBox = new System.Windows.Forms.GroupBox();
            this.holdCBox = new System.Windows.Forms.CheckBox();
            this.readTBox = new System.Windows.Forms.TextBox();
            this.clearBtn = new System.Windows.Forms.Button();
            this.exportBtn = new System.Windows.Forms.Button();
            this.connectionSettingsGBox = new System.Windows.Forms.GroupBox();
            this.connectionLabel = new System.Windows.Forms.Label();
            this.connectionStatusPanel = new System.Windows.Forms.Panel();
            this.baudLabel = new System.Windows.Forms.Label();
            this.portLabel = new System.Windows.Forms.Label();
            this.autoConnectCBox = new System.Windows.Forms.CheckBox();
            this.connectBtn = new System.Windows.Forms.Button();
            this.serialPort = new System.IO.Ports.SerialPort(this.components);
            this.statusBar = new System.Windows.Forms.StatusStrip();
            this.statusLabel = new System.Windows.Forms.ToolStripStatusLabel();
            this.toolStrip1 = new System.Windows.Forms.ToolStrip();
            this.toolStripDropDownButton1 = new System.Windows.Forms.ToolStripDropDownButton();
            this.settingsToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.readDataFormatCBox = new System.Windows.Forms.ComboBox();
            this.saveSettingsToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.sendDataGBox.SuspendLayout();
            this.readDataGBox.SuspendLayout();
            this.connectionSettingsGBox.SuspendLayout();
            this.statusBar.SuspendLayout();
            this.toolStrip1.SuspendLayout();
            this.SuspendLayout();
            // 
            // refreshBtn
            // 
            this.refreshBtn.Location = new System.Drawing.Point(6, 59);
            this.refreshBtn.Name = "refreshBtn";
            this.refreshBtn.Size = new System.Drawing.Size(64, 21);
            this.refreshBtn.TabIndex = 0;
            this.refreshBtn.TabStop = false;
            this.refreshBtn.Text = "Refresh";
            this.refreshBtn.UseVisualStyleBackColor = true;
            this.refreshBtn.Click += new System.EventHandler(this.refreshBtn_Click);
            // 
            // portCBox
            // 
            this.portCBox.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.portCBox.FormattingEnabled = true;
            this.portCBox.Items.AddRange(new object[] {
            "COM5"});
            this.portCBox.Location = new System.Drawing.Point(6, 32);
            this.portCBox.Name = "portCBox";
            this.portCBox.Size = new System.Drawing.Size(64, 21);
            this.portCBox.TabIndex = 0;
            // 
            // baudRateCBox
            // 
            this.baudRateCBox.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.baudRateCBox.FormattingEnabled = true;
            this.baudRateCBox.Items.AddRange(new object[] {
            "9600",
            "115200"});
            this.baudRateCBox.Location = new System.Drawing.Point(76, 32);
            this.baudRateCBox.Name = "baudRateCBox";
            this.baudRateCBox.Size = new System.Drawing.Size(71, 21);
            this.baudRateCBox.TabIndex = 1;
            // 
            // commandCBox
            // 
            this.commandCBox.Enabled = false;
            this.commandCBox.FormattingEnabled = true;
            this.commandCBox.Items.AddRange(new object[] {
            "0x10",
            "0x11"});
            this.commandCBox.Location = new System.Drawing.Point(63, 60);
            this.commandCBox.Name = "commandCBox";
            this.commandCBox.Size = new System.Drawing.Size(51, 21);
            this.commandCBox.TabIndex = 4;
            this.commandCBox.Text = "0x10";
            this.commandCBox.KeyDown += new System.Windows.Forms.KeyEventHandler(this.commandCBox_KeyDown);
            // 
            // typeCBox
            // 
            this.typeCBox.Enabled = false;
            this.typeCBox.FormattingEnabled = true;
            this.typeCBox.Items.AddRange(new object[] {
            "0x55",
            "0xAA",
            "0xBB"});
            this.typeCBox.Location = new System.Drawing.Point(6, 60);
            this.typeCBox.Name = "typeCBox";
            this.typeCBox.Size = new System.Drawing.Size(51, 21);
            this.typeCBox.TabIndex = 3;
            this.typeCBox.Text = "0x55";
            this.typeCBox.KeyDown += new System.Windows.Forms.KeyEventHandler(this.typeCBox_KeyDown);
            // 
            // sendDataGBox
            // 
            this.sendDataGBox.Controls.Add(this.sendAsFileBtn);
            this.sendDataGBox.Controls.Add(this.browseSendBtn);
            this.sendDataGBox.Controls.Add(this.browseSendTBox);
            this.sendDataGBox.Controls.Add(this.dataLabel);
            this.sendDataGBox.Controls.Add(this.commandLabel);
            this.sendDataGBox.Controls.Add(this.typeLabel);
            this.sendDataGBox.Controls.Add(this.sendBtn);
            this.sendDataGBox.Controls.Add(this.typeCBox);
            this.sendDataGBox.Controls.Add(this.commandCBox);
            this.sendDataGBox.Controls.Add(this.dataTBox);
            this.sendDataGBox.Location = new System.Drawing.Point(224, 28);
            this.sendDataGBox.Name = "sendDataGBox";
            this.sendDataGBox.Size = new System.Drawing.Size(259, 90);
            this.sendDataGBox.TabIndex = 5;
            this.sendDataGBox.TabStop = false;
            this.sendDataGBox.Text = "Send Data:";
            // 
            // sendAsFileBtn
            // 
            this.sendAsFileBtn.Enabled = false;
            this.sendAsFileBtn.Location = new System.Drawing.Point(171, 36);
            this.sendAsFileBtn.Name = "sendAsFileBtn";
            this.sendAsFileBtn.Size = new System.Drawing.Size(81, 23);
            this.sendAsFileBtn.TabIndex = 8;
            this.sendAsFileBtn.Text = "Send as File";
            this.sendAsFileBtn.UseVisualStyleBackColor = true;
            this.sendAsFileBtn.Click += new System.EventHandler(this.sendAsFileBtn_Click);
            // 
            // browseSendBtn
            // 
            this.browseSendBtn.Location = new System.Drawing.Point(171, 15);
            this.browseSendBtn.Name = "browseSendBtn";
            this.browseSendBtn.Size = new System.Drawing.Size(81, 22);
            this.browseSendBtn.TabIndex = 7;
            this.browseSendBtn.Text = "Browse";
            this.browseSendBtn.UseVisualStyleBackColor = true;
            this.browseSendBtn.Click += new System.EventHandler(this.browseSendBtn_Click);
            // 
            // browseSendTBox
            // 
            this.browseSendTBox.Location = new System.Drawing.Point(6, 16);
            this.browseSendTBox.Name = "browseSendTBox";
            this.browseSendTBox.Size = new System.Drawing.Size(165, 20);
            this.browseSendTBox.TabIndex = 14;
            this.browseSendTBox.TabStop = false;
            // 
            // dataLabel
            // 
            this.dataLabel.AutoSize = true;
            this.dataLabel.Location = new System.Drawing.Point(117, 44);
            this.dataLabel.Name = "dataLabel";
            this.dataLabel.Size = new System.Drawing.Size(33, 13);
            this.dataLabel.TabIndex = 13;
            this.dataLabel.Text = "Data:";
            // 
            // commandLabel
            // 
            this.commandLabel.AutoSize = true;
            this.commandLabel.Location = new System.Drawing.Point(60, 44);
            this.commandLabel.Name = "commandLabel";
            this.commandLabel.Size = new System.Drawing.Size(31, 13);
            this.commandLabel.TabIndex = 12;
            this.commandLabel.Text = "Cmd:";
            // 
            // typeLabel
            // 
            this.typeLabel.AutoSize = true;
            this.typeLabel.Location = new System.Drawing.Point(3, 44);
            this.typeLabel.Name = "typeLabel";
            this.typeLabel.Size = new System.Drawing.Size(34, 13);
            this.typeLabel.TabIndex = 11;
            this.typeLabel.Text = "Type:";
            // 
            // sendBtn
            // 
            this.sendBtn.Enabled = false;
            this.sendBtn.Location = new System.Drawing.Point(177, 60);
            this.sendBtn.Name = "sendBtn";
            this.sendBtn.Size = new System.Drawing.Size(75, 22);
            this.sendBtn.TabIndex = 6;
            this.sendBtn.Text = "Send";
            this.sendBtn.UseVisualStyleBackColor = true;
            this.sendBtn.Click += new System.EventHandler(this.sendBtn_Click);
            // 
            // dataTBox
            // 
            this.dataTBox.Enabled = false;
            this.dataTBox.Location = new System.Drawing.Point(120, 61);
            this.dataTBox.Name = "dataTBox";
            this.dataTBox.Size = new System.Drawing.Size(51, 20);
            this.dataTBox.TabIndex = 5;
            this.dataTBox.Text = "0x3C";
            this.dataTBox.KeyDown += new System.Windows.Forms.KeyEventHandler(this.dataTBox_KeyDown);
            // 
            // readDataGBox
            // 
            this.readDataGBox.Controls.Add(this.readDataFormatCBox);
            this.readDataGBox.Controls.Add(this.holdCBox);
            this.readDataGBox.Controls.Add(this.readTBox);
            this.readDataGBox.Controls.Add(this.clearBtn);
            this.readDataGBox.Controls.Add(this.exportBtn);
            this.readDataGBox.Location = new System.Drawing.Point(12, 124);
            this.readDataGBox.Name = "readDataGBox";
            this.readDataGBox.Size = new System.Drawing.Size(471, 352);
            this.readDataGBox.TabIndex = 6;
            this.readDataGBox.TabStop = false;
            this.readDataGBox.Text = "Read Data:";
            // 
            // holdCBox
            // 
            this.holdCBox.AutoSize = true;
            this.holdCBox.Location = new System.Drawing.Point(416, 329);
            this.holdCBox.Name = "holdCBox";
            this.holdCBox.Size = new System.Drawing.Size(48, 17);
            this.holdCBox.TabIndex = 13;
            this.holdCBox.TabStop = false;
            this.holdCBox.Text = "Hold";
            this.holdCBox.UseVisualStyleBackColor = true;
            // 
            // readTBox
            // 
            this.readTBox.Location = new System.Drawing.Point(6, 19);
            this.readTBox.MaxLength = 1240000;
            this.readTBox.Multiline = true;
            this.readTBox.Name = "readTBox";
            this.readTBox.ReadOnly = true;
            this.readTBox.ScrollBars = System.Windows.Forms.ScrollBars.Vertical;
            this.readTBox.Size = new System.Drawing.Size(458, 304);
            this.readTBox.TabIndex = 8;
            this.readTBox.TabStop = false;
            // 
            // clearBtn
            // 
            this.clearBtn.Location = new System.Drawing.Point(358, 326);
            this.clearBtn.Name = "clearBtn";
            this.clearBtn.Size = new System.Drawing.Size(52, 22);
            this.clearBtn.TabIndex = 12;
            this.clearBtn.Text = "Clear";
            this.clearBtn.UseVisualStyleBackColor = true;
            this.clearBtn.Click += new System.EventHandler(this.clearBtn_Click);
            // 
            // exportBtn
            // 
            this.exportBtn.Location = new System.Drawing.Point(303, 326);
            this.exportBtn.Name = "exportBtn";
            this.exportBtn.Size = new System.Drawing.Size(52, 22);
            this.exportBtn.TabIndex = 11;
            this.exportBtn.Text = "Export";
            this.exportBtn.UseVisualStyleBackColor = true;
            this.exportBtn.Click += new System.EventHandler(this.exportBtn_Click);
            // 
            // connectionSettingsGBox
            // 
            this.connectionSettingsGBox.Controls.Add(this.connectionLabel);
            this.connectionSettingsGBox.Controls.Add(this.connectionStatusPanel);
            this.connectionSettingsGBox.Controls.Add(this.baudLabel);
            this.connectionSettingsGBox.Controls.Add(this.portLabel);
            this.connectionSettingsGBox.Controls.Add(this.autoConnectCBox);
            this.connectionSettingsGBox.Controls.Add(this.refreshBtn);
            this.connectionSettingsGBox.Controls.Add(this.portCBox);
            this.connectionSettingsGBox.Controls.Add(this.connectBtn);
            this.connectionSettingsGBox.Controls.Add(this.baudRateCBox);
            this.connectionSettingsGBox.Location = new System.Drawing.Point(12, 28);
            this.connectionSettingsGBox.Name = "connectionSettingsGBox";
            this.connectionSettingsGBox.Size = new System.Drawing.Size(206, 90);
            this.connectionSettingsGBox.TabIndex = 7;
            this.connectionSettingsGBox.TabStop = false;
            this.connectionSettingsGBox.Text = "Connection Settings:";
            // 
            // connectionLabel
            // 
            this.connectionLabel.AutoSize = true;
            this.connectionLabel.Location = new System.Drawing.Point(150, 16);
            this.connectionLabel.Name = "connectionLabel";
            this.connectionLabel.Size = new System.Drawing.Size(48, 13);
            this.connectionLabel.TabIndex = 18;
            this.connectionLabel.Text = "ConStat:";
            // 
            // connectionStatusPanel
            // 
            this.connectionStatusPanel.BackColor = System.Drawing.Color.Red;
            this.connectionStatusPanel.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.connectionStatusPanel.Location = new System.Drawing.Point(153, 32);
            this.connectionStatusPanel.Name = "connectionStatusPanel";
            this.connectionStatusPanel.Size = new System.Drawing.Size(38, 21);
            this.connectionStatusPanel.TabIndex = 17;
            // 
            // baudLabel
            // 
            this.baudLabel.AutoSize = true;
            this.baudLabel.Location = new System.Drawing.Point(73, 16);
            this.baudLabel.Name = "baudLabel";
            this.baudLabel.Size = new System.Drawing.Size(61, 13);
            this.baudLabel.TabIndex = 16;
            this.baudLabel.Text = "Baud Rate:";
            // 
            // portLabel
            // 
            this.portLabel.AutoSize = true;
            this.portLabel.Location = new System.Drawing.Point(3, 16);
            this.portLabel.Name = "portLabel";
            this.portLabel.Size = new System.Drawing.Size(29, 13);
            this.portLabel.TabIndex = 15;
            this.portLabel.Text = "Port:";
            // 
            // autoConnectCBox
            // 
            this.autoConnectCBox.AutoSize = true;
            this.autoConnectCBox.Location = new System.Drawing.Point(153, 62);
            this.autoConnectCBox.Name = "autoConnectCBox";
            this.autoConnectCBox.Size = new System.Drawing.Size(40, 17);
            this.autoConnectCBox.TabIndex = 14;
            this.autoConnectCBox.TabStop = false;
            this.autoConnectCBox.Text = "AC";
            this.autoConnectCBox.UseVisualStyleBackColor = true;
            // 
            // connectBtn
            // 
            this.connectBtn.Location = new System.Drawing.Point(76, 59);
            this.connectBtn.Name = "connectBtn";
            this.connectBtn.Size = new System.Drawing.Size(71, 21);
            this.connectBtn.TabIndex = 2;
            this.connectBtn.Text = "Connect";
            this.connectBtn.UseVisualStyleBackColor = true;
            this.connectBtn.Click += new System.EventHandler(this.connectBtn_Click);
            // 
            // serialPort
            // 
            this.serialPort.DataReceived += new System.IO.Ports.SerialDataReceivedEventHandler(this.serialPort_DataReceived);
            // 
            // statusBar
            // 
            this.statusBar.AllowMerge = false;
            this.statusBar.Enabled = false;
            this.statusBar.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.statusLabel});
            this.statusBar.Location = new System.Drawing.Point(0, 485);
            this.statusBar.Name = "statusBar";
            this.statusBar.Size = new System.Drawing.Size(492, 22);
            this.statusBar.Stretch = false;
            this.statusBar.TabIndex = 8;
            this.statusBar.Text = "statusStrip1";
            // 
            // statusLabel
            // 
            this.statusLabel.Name = "statusLabel";
            this.statusLabel.Size = new System.Drawing.Size(132, 17);
            this.statusLabel.Text = "Waiting for connection.";
            // 
            // toolStrip1
            // 
            this.toolStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.toolStripDropDownButton1});
            this.toolStrip1.Location = new System.Drawing.Point(0, 0);
            this.toolStrip1.Name = "toolStrip1";
            this.toolStrip1.Size = new System.Drawing.Size(492, 25);
            this.toolStrip1.TabIndex = 9;
            this.toolStrip1.Text = "toolStrip1";
            // 
            // toolStripDropDownButton1
            // 
            this.toolStripDropDownButton1.DisplayStyle = System.Windows.Forms.ToolStripItemDisplayStyle.Text;
            this.toolStripDropDownButton1.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.settingsToolStripMenuItem,
            this.saveSettingsToolStripMenuItem});
            this.toolStripDropDownButton1.ImageTransparentColor = System.Drawing.Color.Magenta;
            this.toolStripDropDownButton1.Name = "toolStripDropDownButton1";
            this.toolStripDropDownButton1.Size = new System.Drawing.Size(38, 22);
            this.toolStripDropDownButton1.Text = "File";
            this.toolStripDropDownButton1.ToolTipText = "Settings";
            // 
            // settingsToolStripMenuItem
            // 
            this.settingsToolStripMenuItem.Name = "settingsToolStripMenuItem";
            this.settingsToolStripMenuItem.Size = new System.Drawing.Size(189, 22);
            this.settingsToolStripMenuItem.Text = "Options";
            this.settingsToolStripMenuItem.Click += new System.EventHandler(this.settingsToolStripMenuItem_Click);
            // 
            // readDataFormatCBox
            // 
            this.readDataFormatCBox.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.readDataFormatCBox.FormattingEnabled = true;
            this.readDataFormatCBox.Items.AddRange(new object[] {
            "HEX",
            "ASCII"});
            this.readDataFormatCBox.Location = new System.Drawing.Point(6, 325);
            this.readDataFormatCBox.Name = "readDataFormatCBox";
            this.readDataFormatCBox.Size = new System.Drawing.Size(64, 21);
            this.readDataFormatCBox.TabIndex = 10;
            // 
            // saveSettingsToolStripMenuItem
            // 
            this.saveSettingsToolStripMenuItem.Name = "saveSettingsToolStripMenuItem";
            this.saveSettingsToolStripMenuItem.ShortcutKeyDisplayString = "Ctrl + S";
            this.saveSettingsToolStripMenuItem.ShortcutKeys = ((System.Windows.Forms.Keys)((System.Windows.Forms.Keys.Control | System.Windows.Forms.Keys.S)));
            this.saveSettingsToolStripMenuItem.Size = new System.Drawing.Size(189, 22);
            this.saveSettingsToolStripMenuItem.Text = "Save Settings";
            this.saveSettingsToolStripMenuItem.Click += new System.EventHandler(this.saveSettingsToolStripMenuItem_Click);
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(492, 507);
            this.Controls.Add(this.toolStrip1);
            this.Controls.Add(this.statusBar);
            this.Controls.Add(this.connectionSettingsGBox);
            this.Controls.Add(this.readDataGBox);
            this.Controls.Add(this.sendDataGBox);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog;
            this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
            this.Name = "Form1";
            this.Text = "SeriTerm";
            this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.Form1_FormClosing);
            this.sendDataGBox.ResumeLayout(false);
            this.sendDataGBox.PerformLayout();
            this.readDataGBox.ResumeLayout(false);
            this.readDataGBox.PerformLayout();
            this.connectionSettingsGBox.ResumeLayout(false);
            this.connectionSettingsGBox.PerformLayout();
            this.statusBar.ResumeLayout(false);
            this.statusBar.PerformLayout();
            this.toolStrip1.ResumeLayout(false);
            this.toolStrip1.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Button refreshBtn;
        private System.Windows.Forms.ComboBox portCBox;
        private System.Windows.Forms.ComboBox baudRateCBox;
        private System.Windows.Forms.ComboBox commandCBox;
        private System.Windows.Forms.ComboBox typeCBox;
        private System.Windows.Forms.GroupBox sendDataGBox;
        private System.Windows.Forms.Button sendBtn;
        private System.Windows.Forms.TextBox dataTBox;
        private System.Windows.Forms.GroupBox readDataGBox;
        private System.Windows.Forms.GroupBox connectionSettingsGBox;
        private System.Windows.Forms.CheckBox autoConnectCBox;
        private System.Windows.Forms.Button connectBtn;
        private System.Windows.Forms.TextBox readTBox;
        private System.Windows.Forms.Button exportBtn;
        private System.Windows.Forms.Button clearBtn;
        private System.Windows.Forms.CheckBox holdCBox;
        private System.IO.Ports.SerialPort serialPort;
        private System.Windows.Forms.Label commandLabel;
        private System.Windows.Forms.Label typeLabel;
        private System.Windows.Forms.Label dataLabel;
        private System.Windows.Forms.Label portLabel;
        private System.Windows.Forms.Label baudLabel;
        private System.Windows.Forms.Button sendAsFileBtn;
        private System.Windows.Forms.Button browseSendBtn;
        private System.Windows.Forms.TextBox browseSendTBox;
        private System.Windows.Forms.Panel connectionStatusPanel;
        private System.Windows.Forms.Label connectionLabel;
        private System.Windows.Forms.StatusStrip statusBar;
        private System.Windows.Forms.ToolStripStatusLabel statusLabel;
        private System.Windows.Forms.ToolStrip toolStrip1;
        private System.Windows.Forms.ToolStripDropDownButton toolStripDropDownButton1;
        private System.Windows.Forms.ToolStripMenuItem settingsToolStripMenuItem;
        private System.Windows.Forms.ComboBox readDataFormatCBox;
        private System.Windows.Forms.ToolStripMenuItem saveSettingsToolStripMenuItem;
    }
}

