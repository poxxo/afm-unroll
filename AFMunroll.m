function varargout = AFMunroll( file, frames, scanDir, varargin )
%AFMUNROLL Unroll AFM image(s) into time sequence(s).
%   Scanned trace and retrace frame(s) are passed into the function as an 
%   .ibw (IGOR Pro binary wave) or .txt (exported from Gwyddion) file. The
%   corresponding data is returned as a time sequence.
%
%   INPUTS:
%   file: Path to .ibw or .txt file. The file format is inferred from the
%   extension. The input file must contain at least two images: the trace
%   and retrace image of at least one quantity. NOTE: .txt support will be
%   added later.
%   frames: Cell array containing the names of images to convert to time
%   sequences. For each element <name> in frames, "<name>Trace" and
%   "<name>Retrace" must be found as images in the input file. A string
%   containg a single image name is also accepted.
%   scanDir: Scan direction. Accepted inputs are "FrameUp" and "FrameDown".
%   scanRate (optional): The rate at which each (horizontal) line in the
%   image is captured (in Hz).
%   pointsAndLines (optional): The number of pixels in each line.
%
%   OUTPUTS:
%   sequence: An nFrame by nPix matrix, where nFrame is the number of
%   elements in frames (1 if frames is a string), and nPix is the length of
%   each time sequence, which is twice the number of pixels in each image.
%   time (optional): If scanDir and scanRate are provided, then time is the
%   time sequence (in s, starting at zero) associated with sequence.

[~, ~, ext] = fileparts(file);
assert(strcmp(ext, '.ibw') || strcmp(ext, '.txt'), 'Expected .ibw or .txt as file extension');
assert(strcmp(scanDir, 'FrameUp') || strcmp(scanDir, 'FrameDown'), 'scanDir should be ''FrameUp'' or ''FrameDown''');
assert(length(varargin) == 0 || length(varargin) == 2, 'Either both or none of scanRate and pointsAndLines must be provided');

addpath('Igor2Matlab');

switch ext
    case '.ibw'
        A = IBWread(file);
        nChan = A.waveHeader.nDim(A.Ndim);
        assert(nChan >= 1, 'Expected at least one image');
        tok = repmat(char(0), 1, 32);

        channels = cell(1, nChan);
        begin = strfind(A.footer, tok) + 32;
        for i = 1:nChan
            chan = A.footer(begin:(begin+31));
            spaces = strfind(chan, char(0));
            chan = chan(1:(spaces(1) - 1));
            % chan(regexp(chan, char(0))) = [];
            channels{i} = chan;
            begin = begin+32;
        end
        
        frameIndices = [];
        
        if isempty(frames)  % include all images ending in Trace or Retrace
            frameNames = {};
            for i = 1:length(channels)
                nameFoundFlag = false;
                traceOccurrences = strfind(fliplr(channels{i}), fliplr('Trace'));
                retraceOccurrences = strfind(fliplr(channels{i}), fliplr('Retrace'));
                if ~isempty(traceOccurrences) && traceOccurrences(1) == 1    % channel name ends with 'Trace'
                    for j = 1:length(frameNames)
                        if strcmp(frameNames{j}, channels{i}(1:(end - length('Trace'))))
                            frameIndices(j, 1) = i;
                            nameFoundFlag = true;
                            break;
                        end
                    end
                    if ~nameFoundFlag
                        frameNames{length(frameNames) + 1} = channels{i}(1:(end - length('Trace')));
                        frameIndices = [frameIndices; [i, 0]];
                    end
                elseif ~isempty(retraceOccurrences) && retraceOccurrences(1) == 1    % channel name ends with 'Retrace'
                    for j = 1:length(frameNames)
                        if strcmp(frameNames{j}, channels{i}(1:(end - length('Retrace'))))
                            frameIndices(j, 2) = i;
                            nameFoundFlag = true;
                            break;
                        end
                    end
                    if ~nameFoundFlag
                        frameNames{length(frameNames) + 1} = channels{i}(1:(end - length('Retrace')));
                        frameIndices = [frameIndices; [0, i]];
                    end
                end
            end
            
        elseif ischar(frames) && size(frames, 1) == 1   % frames is a string: the name of an image
            frameNames = {frames};
            for i = 1:length(channels)
                if strcmp([frames, 'Trace'], channels{i})
                    if isempty(frameIndices)
                        frameIndices = [i, 0];
                    else
                        frameIndices(1) = i;
                    end
                elseif strcmp([frames, 'Retrace'], channels{i})
                    if isempty(frameIndices)
                        frameIndices = [0, i];
                    else
                        frameIndices(2) = i;
                    end
                end
            end
        elseif iscell(frames)   % frames is a cell array containing one or more image names
            frameNames = frames;
            for j = 1:length(frames)
                for i = 1:length(channels)
                    if strcmp([frameNames{j}, 'Trace'], channels{i})
                        if size(frameIndices, 1) < j
                            frameIndices = [frameIndices; [i, 0]];
                        else
                            frameIndices(j, 1) = i;
                        end
                    elseif strcmp([frameNames{j}, 'Retrace'], channels{i})
                        if size(frameIndices, 1) < j
                            frameIndices = [frameIndices; [0, i]];
                        else
                            frameIndices(j, 2) = i;
                        end
                    end
                end
            end
            assert(length(frames) == size(frameIndices, 1), 'Not all frames could be found');
        end
        
        assert(~isempty(frameIndices), 'No trace/retrace pair found');
        assert(isempty(find(frameIndices == 0, 1)), 'A trace image has no corresponding trace image, or vice versa');
        
        nPix = 2*numel(A.y(:, :, frameIndices(1, 1)));
        sequence = zeros(length(frameNames), nPix);
        for i = 1:length(frameNames)
            switch scanDir
                case 'FrameDown'
                    sequence(i, :) = reshape(fliplr([A.y(:,:,frameIndices(i, 1)); flipud(A.y(:,:,frameIndices(i, 2)))]), 1, []);
                case 'FrameUp'
                    sequence(i, :) = reshape([A.y(:,:,frameIndices(i, 1)); flipud(A.y(:,:,frameIndices(i, 2)))], 1, []);

%                     case 'FrameDown'
%                         sequence(i, :) = reshape([A.y(:,:,frameIndices(i, 1)), fliplr(A.y(:,:,frameIndices(i, 2)))].', []);
%                     case 'FrameUp'
%                         sequence(i, :) = reshape(fliplr([A.y(:,:,frameIndices(i, 1)), fliplr(A.y(:,:,frameIndices(i, 2)))].'), []);
            end
        end
        
    case '.txt'
        % To be implemented later %
        error('.txt support has not yet been implemented');

end

varargout{1} = sequence;
if ~isempty(varargin)
    varargout{2} = linspace(0, size(sequence, 2)/(2*varargin{1}*varargin{2}), size(sequence, 2));
end

end

