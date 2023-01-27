% Codigo de coleta de Eye Tracking 
% 1. Fecha variaveis abertas
% 2. Adiciona o folder ao path 
% 3. Cria o primeiro handler de conexão com o equipamento GP3
% 4. Envia mensagem ao USER do GP3 que irá começar a calibração
% 5. Instancia terminal de coleta de EEG
% 6. Aguarda conexão do terminal de coleta de EEG com o aparelho GP3
% 7. Armazena dados de ET em arquivo .txt
%% Fechar todas as variáveis antigas
close all;
clear all;

%% Adicionar pastas e subpastas com as funções no path
addpath('C:\Users\anapa\Documents\gp3_mindwave_data_collection')

%% Criar a conexão 1
conexao_1 = tcpip('127.0.0.1', 4242);
conexao_1.InputBufferSize = 4096;
fopen(conexao_1);
conexao_1.Terminator = 'CR/LF';

%% Informar que vai comecar a calibração
% message = 'START_CALIBRATION';
% command = ['<SET ID="USER_DATA" VALUE="' message '" />'];
% fprintf(conexao_1, command);


% %% Iniciar a calibração
% fprintf(conexao_1, '<SET ID="CALIBRATE_RESET"/>');
% fprintf(conexao_1, '<SET ID="CALIBRATE_SHOW" STATE="1" />');
% fprintf(conexao_1, '<SET ID="CALIBRATE_START" STATE="1" />');
% pause(20); %tempo do delay em segundos
% fprintf(conexao_1,'<SET ID="CALIBRATE_START" STATE="0" />');
% fprintf(conexao_1,'<SET ID="CALIBRATE_SHOW" STATE="0" />');
% 
% fprintf(conexao_1, '<GET ID="CALIBRATE_RESULT_SUMMARY" />');
% while  conexao_1.BytesAvailable > 0
%     dataReceivedCalibration = fscanf(conexao_1);
%     disp(dataReceivedCalibration)
% end
% %% Continuar ou Refazer a Calibração
% promptMessage = sprintf('Deseja continuar ou refazer a calibração?');
% titleBarCaption = 'Continuar?';
% button = questdlg(promptMessage, titleBarCaption, 'Continuar', 'Refazer', 'Continuar');
% if strcmpi(button, 'Refazer')
%     fprintf(conexao_1, '<SET ID="CALIBRATE_RESET"/>');
%     fprintf(conexao_1, '<SET ID="CALIBRATE_SHOW" STATE="1" />');
%     fprintf(conexao_1, '<SET ID="CALIBRATE_START" STATE="1" />');
%     pause(20); %tempo do delay em segundos
%     fprintf(conexao_1,'<SET ID="CALIBRATE_START" STATE="0" />');
%     fprintf(conexao_1,'<SET ID="CALIBRATE_SHOW" STATE="0" />');
%     fprintf(conexao_1, '<GET ID="CALIBRATE_RESULT_SUMMARY" />');
%     while  conexao_1.BytesAvailable > 0
%         dataReceivedCalibration = fscanf(conexao_1);
%         disp(dataReceivedCalibration)
%     end
% end



%% Habilitar tipos de dado de interesse
fprintf(conexao_1, '<SET ID="ENABLE_SEND_TIME" STATE="1" />');
fprintf(conexao_1, '<SET ID="ENABLE_SEND_COUNTER" STATE="1" />');
fprintf(conexao_1, '<SET ID="ENABLE_SEND_USER_DATA" STATE="1" />');
fprintf(conexao_1, '<SET ID="ENABLE_SEND_BLINK" STATE="1" />');
fprintf(conexao_1, '<SET ID="ENABLE_SEND_DATA" STATE="1" />');


%% Enviar mensagem de estabelecimento de conexao
message = 'TERMINAL1_MESSAGE';
command = ['<SET ID="USER_DATA" VALUE="' message '" />'];
fprintf(conexao_1, command);

%% Definir arquivo para salvar os dados 
DateString = datestr(now, 'dd-mm-yy--HH:MM');
DateString = strrep(DateString, ':', '_');
DateString = strrep(DateString, ' ', '_');
DateString = strrep(DateString, '-', '_');
data_path = "C:\\Users\\anapa\\Documents\\gp3_mindwave_data_collection\\dataset\\ET\\";
outputFileName = sprintf( data_path + "\\sem_REC\\" + DateString + "_piscada_4s.txt");
fileID = fopen(outputFileName,'w');

%% Create header for output file
dataReceived = fscanf(conexao_1);
split = strsplit(dataReceived,'"');

header = {'CNT' 'TIME_GP3' 'BKID' 'BKPMIN' 'USER'};
fprintf(fileID,['TIME\t' repmat('%s\t',1,length(header)) '\n'],header{:});

%% Instanciar Terminal 2
cd 'C:\Users\anapa\Documents\gp3_mindwave_data_collection\scripts\MATLAB'
if exist([pwd, '/Terminal_2.m'], 'file')
    eval(['!matlab -nosplash -nodesktop -r "Terminal_2" &'])
else
    eval(['!matlab -nosplash -nodesktop -r "addpath(genpath(pwd)); Terminal_2" &'])
end

fprintf('\nAguardando o terminal 2\n\n')
pause(.05)


%% Esperando ate encontrar a mensagem em USER enviada pelo Terminal 2
time_start=tic;
while  1
    dataReceived = fscanf(conexao_1);
    split = strsplit(dataReceived,'"');
    current_user_data = split{end-1};
    if strcmp(current_user_data,'TERMINAL2_MESSAGE')
        fprintf('\nConexão GP3 - Terminal 2 identificada\n\n')
        break
    end
    if toc(time_start) > 120
        error('Timeout na conexão com Terminal 2;')
    end
    pause(.01);
end

%% Enviar mensagem de começo de captura
message = 'COLLECTION';
command = ['<SET ID="USER_DATA" VALUE="' message '" />'];
fprintf(conexao_1, command);

%% Capturar BKID por 20 segundos
tic;
while toc <= 120
    if conexao_1.BytesAvailable == 0
        dataReceived = '<REC CNT="0" TIME="0" BKID="0" BKDUR="0.00000" BKPMIN="0" USER="NO_DATA"/>';
        disp(dataReceived)
        split = strsplit(dataReceived,'"');
        if regexp(split{1},'<REC','once')
            value = {};
            for j=2:2:length(split)
                value = [value, split{j}];
            end
            fprintf(fileID,['%s\t' repmat('%s\t',1,length(value)) '\n'], string(datenum(now)), value{:});
        end
    else 
        dataReceived = fscanf(conexao_1);
        disp(dataReceived)
        split = strsplit(dataReceived,'"');
        if regexp(split{1},'<REC','once')
            value = {};
            for j=2:2:length(split)
                value = [value, split{j}];
            end
            fprintf(fileID,['%s\t' repmat('%s\t',1,length(value)) '\n'], string(datenum(now)),value{:});
        end
    end
end
%% parar de coletar dados
message = 'STOP_EYETRACKER';
command = ['<SET ID="USER_DATA" VALUE="' message '" />'];
fprintf(conexao_1, command);

%% fechar a conexão 
fclose(conexao_1);
delete(conexao_1);
clear conexao_1

fprintf('Terminal 1 concluiu a coleta de ET.\n')