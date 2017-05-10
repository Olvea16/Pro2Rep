namespace SerialTerminalApplication
{
    partial class Form2
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
            this.defaultPortLabel = new System.Windows.Forms.Label();
            this.defaultBaudrateLabel = new System.Windows.Forms.Label();
            this.readFilePathLabel = new System.Windows.Forms.Label();
            this.logPathLabel = new System.Windows.Forms.Label();
            this.writeTimeoutLabel = new System.Windows.Forms.Label();
            this.readTimeoutLabel = new System.Windows.Forms.Label();
            this.defaultPortCB = new System.Windows.Forms.ComboBox();
            this.exportPathTB = new System.Windows.Forms.TextBox();
            this.logPathTB = new System.Windows.Forms.TextBox();
            this.writeTimeoutTB = new System.Windows.Forms.TextBox();
            this.defaultBaudrateTB = new System.Windows.Forms.TextBox();
            this.saveBtn = new System.Windows.Forms.Button();
            this.browseExportPathBtn = new System.Windows.Forms.Button();
            this.browseLogPathBtn = new System.Windows.Forms.Button();
            this.readTimeoutTB = new System.Windows.Forms.TextBox();
            this.fileLocationGB = new System.Windows.Forms.GroupBox();
            this.connectionSettingsGB = new System.Windows.Forms.GroupBox();
            this.enableLogCBox = new System.Windows.Forms.CheckBox();
            this.fileLocationGB.SuspendLayout();
            this.connectionSettingsGB.SuspendLayout();
            this.SuspendLayout();
            // 
            // defaultPortLabel
            // 
            this.defaultPortLabel.AutoSize = true;
            this.defaultPortLabel.Location = new System.Drawing.Point(6, 16);
            this.defaultPortLabel.Name = "defaultPortLabel";
            this.defaultPortLabel.Size = new System.Drawing.Size(65, 13);
            this.defaultPortLabel.TabIndex = 2;
            this.defaultPortLabel.Text = "Default port:";
            // 
            // defaultBaudrateLabel
            // 
            this.defaultBaudrateLabel.AutoSize = true;
            this.defaultBaudrateLabel.Location = new System.Drawing.Point(114, 16);
            this.defaultBaudrateLabel.Name = "defaultBaudrateLabel";
            this.defaultBaudrateLabel.Size = new System.Drawing.Size(89, 13);
            this.defaultBaudrateLabel.TabIndex = 3;
            this.defaultBaudrateLabel.Text = "Default baudrate:";
            // 
            // readFilePathLabel
            // 
            this.readFilePathLabel.AutoSize = true;
            this.readFilePathLabel.Location = new System.Drawing.Point(6, 81);
            this.readFilePathLabel.Name = "readFilePathLabel";
            this.readFilePathLabel.Size = new System.Drawing.Size(65, 13);
            this.readFilePathLabel.TabIndex = 5;
            this.readFilePathLabel.Text = "Export Path:";
            // 
            // logPathLabel
            // 
            this.logPathLabel.AutoSize = true;
            this.logPathLabel.Location = new System.Drawing.Point(6, 29);
            this.logPathLabel.Name = "logPathLabel";
            this.logPathLabel.Size = new System.Drawing.Size(53, 13);
            this.logPathLabel.TabIndex = 7;
            this.logPathLabel.Text = "Log Path:";
            // 
            // writeTimeoutLabel
            // 
            this.writeTimeoutLabel.AutoSize = true;
            this.writeTimeoutLabel.Location = new System.Drawing.Point(114, 66);
            this.writeTimeoutLabel.Name = "writeTimeoutLabel";
            this.writeTimeoutLabel.Size = new System.Drawing.Size(98, 13);
            this.writeTimeoutLabel.TabIndex = 8;
            this.writeTimeoutLabel.Text = "Write Timeout [ms]:";
            // 
            // readTimeoutLabel
            // 
            this.readTimeoutLabel.AutoSize = true;
            this.readTimeoutLabel.Location = new System.Drawing.Point(6, 66);
            this.readTimeoutLabel.Name = "readTimeoutLabel";
            this.readTimeoutLabel.Size = new System.Drawing.Size(99, 13);
            this.readTimeoutLabel.TabIndex = 9;
            this.readTimeoutLabel.Text = "Read Timeout [ms]:";
            // 
            // defaultPortCB
            // 
            this.defaultPortCB.FormattingEnabled = true;
            this.defaultPortCB.Location = new System.Drawing.Point(9, 32);
            this.defaultPortCB.Name = "defaultPortCB";
            this.defaultPortCB.Size = new System.Drawing.Size(86, 21);
            this.defaultPortCB.TabIndex = 3;
            // 
            // exportPathTB
            // 
            this.exportPathTB.Location = new System.Drawing.Point(6, 97);
            this.exportPathTB.Name = "exportPathTB";
            this.exportPathTB.Size = new System.Drawing.Size(381, 20);
            this.exportPathTB.TabIndex = 12;
            this.exportPathTB.TabStop = false;
            // 
            // logPathTB
            // 
            this.logPathTB.Location = new System.Drawing.Point(6, 45);
            this.logPathTB.Name = "logPathTB";
            this.logPathTB.Size = new System.Drawing.Size(381, 20);
            this.logPathTB.TabIndex = 1;
            this.logPathTB.TabStop = false;
            // 
            // writeTimeoutTB
            // 
            this.writeTimeoutTB.Location = new System.Drawing.Point(117, 82);
            this.writeTimeoutTB.Name = "writeTimeoutTB";
            this.writeTimeoutTB.Size = new System.Drawing.Size(86, 20);
            this.writeTimeoutTB.TabIndex = 6;
            this.writeTimeoutTB.TextAlign = System.Windows.Forms.HorizontalAlignment.Right;
            // 
            // defaultBaudrateTB
            // 
            this.defaultBaudrateTB.Location = new System.Drawing.Point(117, 33);
            this.defaultBaudrateTB.Name = "defaultBaudrateTB";
            this.defaultBaudrateTB.Size = new System.Drawing.Size(86, 20);
            this.defaultBaudrateTB.TabIndex = 4;
            this.defaultBaudrateTB.TextAlign = System.Windows.Forms.HorizontalAlignment.Right;
            // 
            // saveBtn
            // 
            this.saveBtn.Location = new System.Drawing.Point(402, 245);
            this.saveBtn.Name = "saveBtn";
            this.saveBtn.Size = new System.Drawing.Size(75, 23);
            this.saveBtn.TabIndex = 8;
            this.saveBtn.Text = "Save";
            this.saveBtn.UseVisualStyleBackColor = true;
            this.saveBtn.Click += new System.EventHandler(this.saveBtn_Click);
            // 
            // browseExportPathBtn
            // 
            this.browseExportPathBtn.Location = new System.Drawing.Point(382, 96);
            this.browseExportPathBtn.Name = "browseExportPathBtn";
            this.browseExportPathBtn.Size = new System.Drawing.Size(75, 21);
            this.browseExportPathBtn.TabIndex = 2;
            this.browseExportPathBtn.Text = "Browse";
            this.browseExportPathBtn.UseVisualStyleBackColor = true;
            this.browseExportPathBtn.Click += new System.EventHandler(this.browseExportPathBtn_Click);
            // 
            // browseLogPathBtn
            // 
            this.browseLogPathBtn.Location = new System.Drawing.Point(382, 44);
            this.browseLogPathBtn.Name = "browseLogPathBtn";
            this.browseLogPathBtn.Size = new System.Drawing.Size(75, 21);
            this.browseLogPathBtn.TabIndex = 1;
            this.browseLogPathBtn.Text = "Browse";
            this.browseLogPathBtn.UseVisualStyleBackColor = true;
            this.browseLogPathBtn.Click += new System.EventHandler(this.browseLogPathBtn_Click);
            // 
            // readTimeoutTB
            // 
            this.readTimeoutTB.Location = new System.Drawing.Point(9, 82);
            this.readTimeoutTB.Name = "readTimeoutTB";
            this.readTimeoutTB.Size = new System.Drawing.Size(86, 20);
            this.readTimeoutTB.TabIndex = 5;
            this.readTimeoutTB.TextAlign = System.Windows.Forms.HorizontalAlignment.Right;
            // 
            // fileLocationGB
            // 
            this.fileLocationGB.Controls.Add(this.exportPathTB);
            this.fileLocationGB.Controls.Add(this.logPathTB);
            this.fileLocationGB.Controls.Add(this.browseLogPathBtn);
            this.fileLocationGB.Controls.Add(this.browseExportPathBtn);
            this.fileLocationGB.Controls.Add(this.logPathLabel);
            this.fileLocationGB.Controls.Add(this.readFilePathLabel);
            this.fileLocationGB.Location = new System.Drawing.Point(12, 12);
            this.fileLocationGB.Name = "fileLocationGB";
            this.fileLocationGB.Size = new System.Drawing.Size(465, 135);
            this.fileLocationGB.TabIndex = 21;
            this.fileLocationGB.TabStop = false;
            this.fileLocationGB.Text = "File Location Settings:";
            // 
            // connectionSettingsGB
            // 
            this.connectionSettingsGB.Controls.Add(this.defaultPortCB);
            this.connectionSettingsGB.Controls.Add(this.defaultPortLabel);
            this.connectionSettingsGB.Controls.Add(this.readTimeoutTB);
            this.connectionSettingsGB.Controls.Add(this.defaultBaudrateLabel);
            this.connectionSettingsGB.Controls.Add(this.writeTimeoutTB);
            this.connectionSettingsGB.Controls.Add(this.defaultBaudrateTB);
            this.connectionSettingsGB.Controls.Add(this.readTimeoutLabel);
            this.connectionSettingsGB.Controls.Add(this.writeTimeoutLabel);
            this.connectionSettingsGB.Location = new System.Drawing.Point(12, 153);
            this.connectionSettingsGB.Name = "connectionSettingsGB";
            this.connectionSettingsGB.Size = new System.Drawing.Size(221, 115);
            this.connectionSettingsGB.TabIndex = 0;
            this.connectionSettingsGB.TabStop = false;
            this.connectionSettingsGB.Text = "Connection Settings:";
            // 
            // enableLogCBox
            // 
            this.enableLogCBox.AutoSize = true;
            this.enableLogCBox.Location = new System.Drawing.Point(370, 153);
            this.enableLogCBox.Name = "enableLogCBox";
            this.enableLogCBox.Size = new System.Drawing.Size(100, 17);
            this.enableLogCBox.TabIndex = 7;
            this.enableLogCBox.Text = "Enable Logging";
            this.enableLogCBox.UseVisualStyleBackColor = true;
            // 
            // Form2
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(482, 272);
            this.Controls.Add(this.enableLogCBox);
            this.Controls.Add(this.connectionSettingsGB);
            this.Controls.Add(this.fileLocationGB);
            this.Controls.Add(this.saveBtn);
            this.Name = "Form2";
            this.Text = "Form2";
            this.fileLocationGB.ResumeLayout(false);
            this.fileLocationGB.PerformLayout();
            this.connectionSettingsGB.ResumeLayout(false);
            this.connectionSettingsGB.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion
        private System.Windows.Forms.Label defaultPortLabel;
        private System.Windows.Forms.Label defaultBaudrateLabel;
        private System.Windows.Forms.Label readFilePathLabel;
        private System.Windows.Forms.Label logPathLabel;
        private System.Windows.Forms.Label writeTimeoutLabel;
        private System.Windows.Forms.Label readTimeoutLabel;
        private System.Windows.Forms.ComboBox defaultPortCB;
        private System.Windows.Forms.TextBox exportPathTB;
        private System.Windows.Forms.TextBox logPathTB;
        private System.Windows.Forms.TextBox writeTimeoutTB;
        private System.Windows.Forms.TextBox defaultBaudrateTB;
        private System.Windows.Forms.Button saveBtn;
        private System.Windows.Forms.Button browseExportPathBtn;
        private System.Windows.Forms.Button browseLogPathBtn;
        private System.Windows.Forms.TextBox readTimeoutTB;
        private System.Windows.Forms.GroupBox fileLocationGB;
        private System.Windows.Forms.GroupBox connectionSettingsGB;
        private System.Windows.Forms.CheckBox enableLogCBox;
    }
}