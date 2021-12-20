clear all
clc;

%% Radar Specifications 
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Frequency of operation = 77GHz
% Max Range = 200m
% Range Resolution = 1 m
% Max Velocity = 100 m/s
%%%%%%%%%%%%%%%%%%%%%%%%%%%
c = 3e8;
r_resolution = 1;
Max_range = 200;

%speed of light = 3e8
%% User Defined Range and Velocity of target
% *%TODO* :
% define the target's initial position and velocity. Note : Velocity
% remains contant
R = 110; % initial distance of the target
v = -20; % speed of the target

%% FMCW Waveform Generation

% *%TODO* :
%Design the FMCW waveform by giving the specs of each of its parameters.
% Calculate the Bandwidth (B), Chirp Time (Tchirp) and Slope (slope) of the FMCW
% chirp using the requirements above.

B = c / (2 * r_resolution);
Tchirp = 5.5 * 2 * Max_range / c;
Slope = B / Tchirp

%Operating carrier frequency of Radar 
fc= 77e9;             %carrier freq
                             
%The number of chirps in one sequence. Its ideal to have 2^ value for the ease of running the FFT
%for Doppler Estimation. 
Nd=128;                   % #of doppler cells OR #of sent periods % number of chirps

%The number of samples on each chirp. 
Nr=1024;                  %for length of time OR # of range cells

% Timestamp for running the displacement scenario for every sample on each
% chirp
t=linspace(0,Nd*Tchirp,Nr*Nd); %total time for samples


%Creating the vectors for Tx, Rx and Mix based on the total samples input.
Tx=zeros(1,length(t)); %transmitted signal
Rx=zeros(1,length(t)); %received signal
Mix = zeros(1,length(t)); %beat signal

%Similar vectors for range_covered and time delay.
r_t=zeros(1,length(t));
td=zeros(1,length(t));



%% Signal generation and Moving Target simulation
% Running the radar scenario over the time. 

signal_length = length(t);


for i=1:signal_length         
    
    
    % *%TODO* :
    %For each time stamp update the Range of the Target for constant velocity. 
    
    r_t(i) = R + v * t(i);
    td(i)= 2 * r_t(i) / c;
    t_delta = t(i) - td(i);

    
    % *%TODO* :
    %For each time sample we need update the transmitted and
    %received signal. 
    Tx(i) = cos(2 * pi * (fc * t(i) + (Slope * t(i) * t(i) / 2) ));
    Rx (i)  = cos(2 * pi * (fc * t_delta + (Slope * t_delta * t_delta / 2) ));
    
    % *%TODO* :
    %Now by mixing the Transmit and Receive generate the beat signal
    %This is done by element wise matrix multiplication of Transmit and
    %Receiver Signal
    %Mix(i) = cos(2 * pi * (2 * Slope * (R/c) * time + 2 * f_c * (v/c) * time))
    Mix(i) = Tx(i) * Rx(i);
    
end

%% RANGE MEASUREMENT


 % *%TODO* :
%reshape the vector into Nr*Nd array. Nr and Nd here would also define the size of
%Range and Doppler FFT respectively.

X_1d = reshape(Mix, [Nr, Nd]);

 % *%TODO* :
%run the FFT on the beat signal along the range bins dimension (Nr) and
%normalize.
Y_1d = fft(X_1d, [],1);

 % *%TODO* :
% Take the absolute value of FFT output
P2 = abs(Y_1d/Nr);

 % *%TODO* :
% Output of FFT is double sided signal, but we are interested in only one side of the spectrum.
% Hence we throw out half of the samples.
P2_mag = max(P2,[],2);
P1 = P2(1:Nr/2);

%plotting the range

figure ('Name','Range from First FFT')
subplot(2,1,1)
plot(P1) 
title("Range from First FFT");
xlabel('Range (m)');
ylabel('FFT First : Magnitude');
axis ([0 200 0 0.5]);
grid

%% RANGE DOPPLER RESPONSE
% The 2D FFT implementation is already provided here. This will run a 2DFFT
% on the mixed signal (beat signal) output and generate a range doppler
% map.You will implement CFAR on the generated RDM


% Range Doppler Map Generation.

% The output of the 2D FFT is an image that has reponse in the range and
% doppler FFT bins. So, it is important to convert the axis from bin sizes
% to range and doppler based on their Max values.

Mix=reshape(Mix,[Nr,Nd]);

% 2D FFT using the FFT size for both dimensions.
sig_fft2 = fft2(Mix,Nr,Nd);

% Taking just one side of signal from Range dimension.
sig_fft2 = sig_fft2(1:Nr/2,1:Nd);
sig_fft2 = fftshift (sig_fft2);
RDM = abs(sig_fft2);
RDM = 10*log10(RDM) ;

%use the surf function to plot the output of 2DFFT and to show axis in both
%dimensions
doppler_axis = linspace(-100,100,Nd);
range_axis = linspace(-200,200,Nr/2)*((Nr/2)/400);
ff = figure ('Name','Output of 2D FFT in Log scale');
ff,surf(doppler_axis,range_axis,RDM);
%shading interp
colorbar;
title("2D FFT in Log scale");
xlabel('Doppler velocity (m/s)');
ylabel('Range (m)');
zlabel('Signal strength : Log magnitude');

%% CFAR implementation

%Slide Window through the complete Range Doppler Map

% *%TODO* :
%Select the number of Training Cells in both the dimensions.
Tr = 8; %4
Td = 6;  %3

% *%TODO* :
%Select the number of Guard Cells in both dimensions around the Cell under 
%test (CUT) for accurate estimation
Gr = 4; %3
Gd = 4; %2

% *%TODO* :
% offset the threshold by SNR value in dB
offset_db = 10;

% *%TODO* :
%Create a vector to store noise_level for each iteration on training cells
noise_level = zeros(1,1);


%design a loop such that it slides the CUT across range doppler map by
%giving margins at the edges for Training and Guard Cells.
%For every iteration sum the signal level within all the training
%cells. To sum convert the value from logarithmic to linear using db2pow
%function. Average the summed values for all of the training
%cells used. After averaging convert it back to logarithimic using pow2db.
%Further add the offset to it to determine the threshold. Next, compare the
%signal under CUT with this threshold. If the CUT level > threshold assign
%it a value of 1, else equate it to 0.


   % Use RDM[x,y] as the matrix from the output of 2D FFT for implementing
   % CFAR

   max_row = Nr/2 - (2*Tr + 2 * Gr );
   max_col = Nd - (2*Td + 2 * Gd );

   block = zeros(Nr/2,Nd);
   RDM_pow = db2pow(RDM);
   

   for i = 1:max_row
       for j = 1:max_col
            
           noise_level_outer = zeros(1,1);
           noise_level_inner = zeros(1,1);

           

           i_idx = i;
           j_idx = j;

           outer_cnt = 0;
           for a =  i_idx : i_idx + (2 * Tr + 2 * Gr )
                for b = j_idx : j_idx + (2 * Td + 2 * Gd )
                    noise_level_outer = noise_level_outer + RDM_pow(a,b);
                    outer_cnt = outer_cnt +1;
                end
           end
            
           inner_cnt = 0;
           for m = i_idx + Tr : (i_idx + Tr ) + 2 * Gr 
                for n = j_idx + Td  : (j_idx + Td ) + 2 * Gd 
                    noise_level_inner = noise_level_inner + RDM_pow(m,n);
                    inner_cnt = inner_cnt +1;
                end
           end

           noise_level = abs(noise_level_outer - noise_level_inner) / (outer_cnt - inner_cnt);

           cell_x = i + (Tr + Gr);
           cell_y = j + (Td + Gd);
           
           if (RDM(cell_x,cell_y) > pow2db(noise_level) + offset_db)

                block(cell_x,cell_y) = 1 ;
           end
            
       end
   end
   

% *%TODO* :
% The process above will generate a thresholded block, which is smaller 
%than the Range Doppler Map as the CUT cannot be located at the edges of
%matrix. Hence,few cells will not be thresholded. To keep the map size same
% set those values to 0. 

off_threshold = 0;
 
block(1 : Tr + Gr,:) = off_threshold;
block(Nr/2 - (Tr + Gr) + 1 : end, : ) = off_threshold;
block(:, 1 : Td + Gd) = off_threshold;
block(:, Nd - (Td + Gd) + 1 : end  ) = off_threshold;


% *%TODO* :
%display the CFAR output using the Surf function like we did for Range
%Doppler Response output.

ff3 = figure ('Name','CFAR Ouput - Cell Averaging');
ff3,surf(doppler_axis,range_axis,block);
title("CFAR Output");
%shading interp
colorbar;


 
 