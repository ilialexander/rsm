function addDendrites (dCells, expandDendrites, nDCells)
%% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%

global SM

sCells = find(SM.cellLearnPrevious); % pointers to previously learned cells

if ~isempty(sCells)
    for i=1:nDCells
        dC = dCells(i);
        if (expandDendrites (i) < 0) % add new dendrite
            if (SM.numDendritesPerCell(dC) < SM.Nd)
                
                SM.numDendritesPerCell(dC) = SM.numDendritesPerCell(dC)+1; % stores number of dendrite information per cell
                SM.dendriteToCell (SM.newDendriteID) = dC; % adds dendrite ID to SM.dendriteToCell
                expandDendrites (i) = SM.newDendriteID; % accounts for new dendrites
                SM.newDendriteID = SM.newDendriteID + 1; % Dendrites locations in SM.dendriteToCell
                SM.totalDendrites = SM.totalDendrites + 1;

            end
        end % expand synapses of "expandDendrites"
        %% select synapses from active cells in SM.SynapseWithPrevious.  -- only one per
        % column, which is ensured during the selection of the cells to
        % synapse with
        
        nNew = min(SM.Nss, length(sCells));
        if ((SM.numSynpasesPerDendrite (expandDendrites (i)) + nNew) < SM.Ns) % add new Synpases
            SM.numSynpasesPerDendrite (expandDendrites (i)) = SM.numSynpasesPerDendrite (expandDendrites (i)) + nNew;
            
            rp = randperm (length(sCells)); % random permutation vector
            sCells = sCells(rp); % IDs of synaptic Cells
            
            sC = sCells(1:nNew); % sinaptic cells
            
            randPermanence =  (2*SM.P_incr).*rand(size(sC)) + SM.P_initial - SM.P_incr; % calculates permanences
            
            newSynapses = ((SM.newSynapseID) : (SM.newSynapseID + length(sC)-1)); % vector of max 30 random permanences
            
            SM.synapseToDendrite (newSynapses) = expandDendrites (i) * ones(size(newSynapses)); % stores the index of the dendrite the synapses are connected to
            SM.synapsePermanence (newSynapses) = randPermanence; % assign permanences to synapses
            
            SM.synapseToCell (newSynapses) = sC;
            SM.numSynapsesPerCell(sC)  = SM.numSynapsesPerCell(sC) + 1;
            SM.newSynapseID = SM.newSynapseID + length(sC);
            SM.totalSynapses = SM.totalSynapses + length(sC);
        end
    end
end