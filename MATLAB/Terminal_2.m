function Terminal_2
%% Criar a conexão 2
conexao_2 = tcpip('127.0.0.1', 4242);
conexao_2.InputBufferSize = 100000;
fopen(conexao_2);
conexao_2.Terminator = 'CR/LF';

%% Adicionar pastas e subpastas com as funções no path
addpath('C:\Users\anapa\Documents\gp3_mindwave_data_collection')

%% Definir parametros de Conexao 
portnum1 =      4;    
comPortName1 =  sprintf('\\\\.\\COM%d', portnum1);
TG_BAUD_115200 = 115200;
TG_STREAM_PACKETS = 0;
TG_DATA_RAW =             4;

%% Abrir o arquivo de escrita
DateString = datestr(now, 'dd-mm-yy--HH:MM');
DateString = strrep(DateString, ':', '_');
DateString = strrep(DateString, ' ', '_');
DateString = strrep(DateString, '-', '_');
data_path = "C:\\Users\\anapa\\Documents\\gp3_mindwave_data_collection\\dataset\\EEG\\";
outputFileName = sprintf( data_path + "\\sem_REC\\" + DateString + "_piscada_4s.txt");
fileID = fopen(outputFileName,'w');


%% Adicionar pastas e subpastas com as funções no path
addpath('C:\Users\anapa\Documents\gp3_mindwave_data_collection\scripts\requirements');

%% Carregar biblioteca Thinkgear e Criar Conexão com Mindwave
loadlibrary('thinkgear.dll');
fprintf('thinkgear.dll loaded\n');

%% Criar coexão com Mindwave
connectionId1 = calllib('thinkgear', 'TG_GetNewConnectionId');


%% Identificar Erros de Conexão
if ( connectionId1 < 0 )
    error ('ERROR: TG_GetNewConnectionId() returned %d.\n', connectionId1)
end
errCode = calllib('thinkgear', 'TG_Connect',  connectionId1,comPortName1,TG_BAUD_115200,TG_STREAM_PACKETS);
if ( errCode < 0 )
    error( 'ERROR: TG_Connect() returned %d.\n', errCode);
end
fprintf( 'Conexão com Mindwave estabelecida\n' );

%% Habilitar envio de mensagem para USER (GP3)
fprintf(conexao_2, '<SET ID="ENABLE_SEND_TIME" STATE="1" />');
fprintf(conexao_2, '<SET ID="ENABLE_SEND_COUNTER" STATE="1" />');
fprintf(conexao_2, '<SET ID="ENABLE_SEND_USER_DATA" STATE="1" />');
fprintf(conexao_2, '<SET ID="ENABLE_SEND_DATA" STATE="1" />');

%% Esperar até encontrar Conexão do Terminal 1 com o GP3
tic;
while conexao_2.BytesAvailable > 0
    dataReceived2 = fscanf(conexao_2);
    split_conexao2 = strsplit(dataReceived2,'"');
    current_user_data = split_conexao2{end-1};
    if strcmp(current_user_data,'TERMINAL1_MESSAGE')
        fprintf('\nConexão GP3 - Terminal 1 encontrada\n\n')
        break
    end
    if toc > 60
        error('Time out: Conexão GP3 - Terminal 1 nao encontrada;')
    end
    pause(.01);
end

%% Enviar mensagem de estabelecimento de conexao terminal 2 - GP3
message = 'TERMINAL2_MESSAGE';
command = ['<SET ID="USER_DATA" VALUE="' message '" />'];
fprintf(conexao_2, command);
pause(0.5)

%% Create header for output file
dataReceived = fscanf(conexao_2);
split = strsplit(dataReceived,'"');

%%
header = {'RAW_EEG'};
fprintf(fileID,['TIME\t' repmat('%s\t',1,length(header)) '\n'],header{:});

%% Enviar dados do Mindwave Mobile II para GP3 e plotar
j = 0;
i = 0;
tic;
while toc <=  120  %loop for 20 seconds
    if (calllib('thinkgear','TG_ReadPackets',connectionId1,1) == 1)   %if a packet was read...
            if (calllib('thinkgear','TG_GetValueStatus',connectionId1,TG_DATA_RAW) ~= 0)   %if RAW has been updated 
                j = j + 1;
                i = i + 1;
%                 data(j) = calllib('thinkgear','TG_GetValue',connectionId1,TG_DATA_RAW);
%                 total(1, i) = calllib('thinkgear','TG_GetValue',connectionId1,TG_DATA_RAW);
%                 value_EEG = calllib('thinkgear','TG_GetValue',connectionId1,TG_DATA_RAW);
%                 total(2, i) = datenum(now);
                fprintf(fileID,['%s\t' '%u\t' '\n'], string(datenum(now)), calllib('thinkgear','TG_GetValue',connectionId1,TG_DATA_RAW));
            end
                
    end
                
    %     
%     if (j == 256)
%         plot(data)
%         axis([0 255 -2000 2000])
%         drawnow;    
%         j = 0;
%     end

end

% raw = total; %return value of data


%% Clean up
calllib('thinkgear', 'TG_FreeConnection', connectionId1);

%%
fclose(conexao_2);
delete(conexao_2);
fclose(fileID);


clear conexao_2
fprintf('Terminal 2 concluiu a coleta de EEG.\n')

