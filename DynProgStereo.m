dispLevels = 16;
Pocc = 10; % Occlusion penalty

% Read stereo image
left = rgb2gray(imread('Left.png'));
right = rgb2gray(imread('Right.png'));

% Use gaussian filter
left = imgaussfilt(left,0.6,'FilterSize',5);
right = imgaussfilt(right,0.6,'FilterSize',5);

% Get image size
[rows,cols] = size(left);

% Compute matching cost
C = zeros(rows,cols,dispLevels);
for x = 0:dispLevels-1
    rightShifted = [zeros(rows,x),right(:,1:end-x)];
    C(:,:,x+1) = abs(double(left)-double(rightShifted));
end

D = zeros(cols,dispLevels); % Minimum costs
T = zeros(cols,dispLevels); % Transitions
dispMap = zeros(rows,cols);

% For each scanline
for y = 1:rows
    
    % Forward step
    D(1,:) = C(y,1,:);
    for x = 2:cols
        for d = 1:dispLevels
            c1 = D(x-1,d);
            if d > 1
                c2 = D(x-1,d-1)+Pocc;
            else
                c2 = Inf;
            end
            if d < dispLevels
                c3 = D(x-1,d+1)+Pocc;
            else
                c3 = Inf;
            end
            [minCost,minD] = min(D(x-1,:));
            c4 = minCost+Pocc*abs(minD-d);
            %c4 = minCost+Pocc*2; %P2 > P1
            
            % Find minimum cost
            if c1 <= c2 && c1 <= c3 && c1 <= c4
                D(x,d) = C(y,x,d) + c1;
                T(x,d) = d;
            elseif c2 <= c3 && c2 <= c4
                D(x,d) = C(y,x,d) + c2;
                T(x,d) = d-1;
            elseif c3 <= c4
                D(x,d) = C(y,x,d) + c3;
                T(x,d) = d+1;
            else
                D(x,d) = C(y,x,d) + c4;
                T(x,d) = minD;
            end
        end
    end

    % Backtracking
    d = 1;
    for x = cols:-1:1
        dispMap(y,x) = d-1;
        d = T(x,d);
    end
end

% Convert disparity map to image
scaleFactor = 256/dispLevels;
dispImage = uint8(dispMap*scaleFactor);

% Show disparity image
imshow(dispImage)

% Save disparity image
imwrite(dispImage,'Disparity.png')
