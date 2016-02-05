function generateReport(varargin)

% Copyright (c) 2015 Rutgers
% Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
% The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

global filenames startTime fileLogID mailInfo;

read = {'This window allows you to send a message about a suggestion, an issue, or an error that occurred.',...
    'Inputting an e-mail in the return address box will let us get back to once the issue has been resolved'};

if nargin > 1
    % Let log know user is sending report at time
    disp(['CeleST user report at ' datestr(clock)]);
    
    errName = 'Send Report about bug, behavioral issue, or send a suggestion';
    instructions = {'If you encountered a bug, the system froze, or there was some other behavioral issue,',...
        'please include which window you were working with and/or what you were doing when the problem occurred.',...
        'Otherwise feel free to send a suggestion'};
    
    errEncountered = 'User Report';
else
    disp(['CeleST error at ' datestr(clock)]);
    diary off
    % Get error report
    errEncountered = getReport(varargin{1}, 'extended', 'hyperlinks', 'off');
    
    errName = 'Report System Error';
    instructions = {'An error has occurred.',...
        'Please type a brief message describing what you were doing prior to the error. ',...
        'Some useful information may include which window you were using or what was pressed prior to the error'};
end

% Error Reporting Window appears when error is caught
errWindow = figure('Name', errName, 'NumberTitle', 'off','Menubar', 'none', 'Position', [100 100 650 550], 'Visible', 'off');
uicontrol(errWindow, 'Style', 'text', 'String', read, 'HorizontalAlignment', 'left', 'Position', [70 510 510 30]);
uicontrol(errWindow, 'Style', 'text', 'String', instructions, 'HorizontalAlignment', 'left', 'Position', [70 465 510 45]);
uicontrol(errWindow, 'Style', 'text', 'String', {'Return Address:','(E-mail)'}, 'HorizontalAlignment', 'left', 'Position', [70 420 80 30]);
errSender = uicontrol(errWindow, 'Style', 'edit', 'Position', [160 425 365 30]);
uicontrol(errWindow, 'Style', 'text', 'String', 'Subject: ', 'HorizontalAlignment', 'left', 'Position', [70 380 80 30]);
errSubject = uicontrol(errWindow, 'Style', 'edit', 'Position', [160 390 365 30]);
uicontrol(errWindow, 'Style', 'text', 'String', 'Message: ', 'HorizontalAlignment', 'left', 'Position', [70 365 80 15]);
errMessage = uicontrol(errWindow, 'Style', 'edit', 'HorizontalAlignment', 'left', 'Max', 1337, 'Min', 0, 'Position', [50 85 550 275]);
uicontrol(errWindow, 'Style', 'pushbutton', 'String', 'Send', 'Position', [75 20 225 50], 'Callback', @SendReport);
uicontrol(errWindow, 'Style', 'pushbutton', 'String', 'Cancel', 'Position', [325 20 250 50], 'Callback', {@DontSend, errWindow});

retry = 1;
retryWindow = -1;
set(errWindow, 'Visible', 'on');
waitfor(errWindow, 'BeingDeleted','on');

    function SendReport(~, ~)
        % Check for Blank Textbox
        if isempty(get(errMessage, 'String'))
            answer = questdlg('Are you sure you want to send the report with no body in the message?', 'Empty Body Encountered', 'Yes', 'No', 'No');
            if strcmp(answer,'No')
                return
            end
        end
        
        % Setup
        setpref('Internet','SMTP_Server','smtp.gmail.com');
        setpref('Internet','E_mail','celestbugreport@gmail.com');
        setpref('Internet','SMTP_Username','celestbugreport@gmail.com');
        setpref('Internet','SMTP_Password','CElegans1');
        props = java.lang.System.getProperties;
        props.setProperty('mail.smtp.auth','true');
        props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
        props.setProperty('mail.smtp.socketFactory.port','465');
        
        % Create Message
        mailInfo.message = [['CeleST Bug Report at: ' 10 startTime 10 10],...
            ['Error Stack:' 10 errEncountered 10 10],...
            ['From :' get(errSender, 'String') 10 10],... 
            ['User message:' 10 get(errMessage, 'String')]];
        
        % Get Attachments
        mailInfo.attachments = {[filenames.log '/comWinLog'],fileLogID};
        
        % Send Mail
        try
            if retry == 1
                sendmail('celestbugreport@gmail.com', get(errSubject, 'String'), mailInfo.message, mailInfo.attachments);
                msgbox('Message sent successfully');
            end
        catch 
            if isgraphics(retryWindow)
                retry = -1;
                close(retryWindow)
            end
            retryWindow = figure('Name', 'Error Sending Mail', 'NumberTitle', 'off','Menubar', 'none', 'Position', [350 300 650 350]);
            uicontrol(retryWindow, 'Style', 'text', 'Position', [50 80 550 250],...
                'String', {'Fix your internet connection and resend the message', '', 'If you would like to send the report manually please include the text below:', errEncountered});
            uicontrol(retryWindow, 'Style', 'pushbutton', 'String', 'Resend', 'Position', [75 20 225 50], 'Callback', @SendReport);
            uicontrol(retryWindow, 'Style', 'pushbutton', 'String', 'Cancel', 'Position', [325 20 250 50], 'Callback', {@DontSend, retryWindow});
            
            set(errWindow, 'Visible','off')
            set(retryWindow, 'Visible', 'on');
            waitfor(retryWindow, 'BeingDeleted','on');
        end
        if isgraphics(retryWindow)
            close(retryWindow)
        end
        close(errWindow);
    end
    function DontSend(~,~,window)
        if isgraphics(window)
            close(window);
        end
    end
end
