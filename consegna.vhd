--
--                  Politecnico di Milano
--
--        Studente: Caravano Andrea
--
--            A.A.: 2022/2023
--    Consegna del 15/05/2023
--
--     Descrizione: Reti Logiche: Prova Finale
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity project_reti_logiche is
         port (
             i_clk   : in std_logic;
             i_rst   : in std_logic;
             i_start : in std_logic;
             i_w     : in std_logic;
             o_z0    : out std_logic_vector(7 downto 0);
             o_z1    : out std_logic_vector(7 downto 0);
             o_z2    : out std_logic_vector(7 downto 0);
             o_z3    : out std_logic_vector(7 downto 0);
             o_done  : out std_logic;
             o_mem_addr : out std_logic_vector(15 downto 0);
             i_mem_data : in std_logic_vector(7 downto 0);
             o_mem_we   : out std_logic;
             o_mem_en   : out std_logic
         );
end project_reti_logiche;

architecture pf_arch of project_reti_logiche is

    -- FSM
    type S is (WAIT_START, READ_FIRST, READ_SECOND, READ_ADDR, WAIT_DATA, READ_AND_OUT);
    signal curr_state : S;
    
    -- selezione uscita e segnali di appoggio
    signal choose : std_logic_vector(0 to 1);
    signal addr : std_logic_vector(0 to 15) := (others => '0');
    signal conta : integer range 0 to 16 := 0;
    
    -- buffer: segnali di uscita da valorizzare a DONE = 1
    signal buff_z0 : std_logic_vector(7 downto 0) := (others => '0');
    signal buff_z1 : std_logic_vector(7 downto 0) := (others => '0');
    signal buff_z2 : std_logic_vector(7 downto 0) := (others => '0');
    signal buff_z3 : std_logic_vector(7 downto 0) := (others => '0');
    
    begin
    
    -- Funzione delta della macchina a stati finiti (FSM)
    fsm_delta : process(i_clk, i_rst)
    begin
        -- segnali costanti
        o_mem_en <= '1';
        o_mem_we <= '0';
    
        if i_rst = '1' then
            -- delta stato
            curr_state <= WAIT_START;
        elsif i_clk'event and i_clk='1' then
            case curr_state is
                when WAIT_START =>
                    if i_start='1' then
                        -- delta stato
                        curr_state <= READ_FIRST;
                    end if;
                when READ_FIRST =>
                    if i_start='1' then
                        -- delta stato
                        curr_state <= READ_SECOND;
                    end if;
                when READ_SECOND =>
                    if i_start='1' then
                        -- delta stato
                        curr_state <= READ_ADDR;
                    elsif i_start='0' then
                        -- delta stato
                        curr_state <= WAIT_DATA;
                    end if;
                when READ_ADDR =>
                    if i_start='0' then
                        -- delta stato
                        curr_state <= WAIT_DATA;
                    end if;
                when WAIT_DATA =>
                    -- stato di sola attesa di un ciclo
                    -- delta stato
                    curr_state <= READ_AND_OUT;
                when READ_AND_OUT =>
                    -- delta stato
                    curr_state <= WAIT_START;
                when others =>
            end case;
        end if;
     end process;
    
    -- Logica implementativa della macchina a stati finiti (FSM)
    fsm_logic : process(i_clk, i_rst)
    begin
        if i_rst = '1' then
            -- stato iniziale ciclo
            o_done <= '0';
                    
            -- reimpostazione uscite
            o_z0 <= "00000000";
            o_z1 <= "00000000";
            o_z2 <= "00000000";
            o_z3 <= "00000000";
            
            -- reimpostazione buffer segnali di uscita
            buff_z0 <= (others => '0');
            buff_z1 <= (others => '0');
            buff_z2 <= (others => '0');
            buff_z3 <= (others => '0');
            
            -- reimpostazione parametri di appoggio
            addr <= (others => '0');
            conta <= 0;
        elsif i_clk'event and i_clk='1' then
            case curr_state is
                when WAIT_START =>
                    -- stato iniziale ciclo
                    o_done <= '0';
                    
                    -- reimpostazione uscite
                    o_z0 <= "00000000";
                    o_z1 <= "00000000";
                    o_z2 <= "00000000";
                    o_z3 <= "00000000";
            
                    -- reimpostazione parametri di appoggio
                    addr <= (others => '0');
                    conta <= 0;
                    
                    if i_start='1' then
                        -- inizializza segnali logici temporanei
                        conta <= 0;
                        addr <= (others => '0');
                        
                        -- imposto bit 0 scelta
                        choose(0) <= i_w;
                    end if;
                when READ_FIRST =>
                    if i_start='1' then
                        -- imposto bit 1 scelta
                        choose(1) <= i_w;
                    end if;
                when READ_SECOND =>
                    if i_start='1' then
                        -- sequenza indirizzo per come letta
                        addr(conta) <= i_w;
                        -- contatore
                        conta <= conta + 1;
                    elsif i_start='0' then
                        -- logica per lettura e stampa
                        
                        -- riempimento indirizzo con 0
                        o_mem_addr <= (others => '0');
                        
                        -- ciclo costante per sintesi
                        for i in 0 to 15 loop
                            if(i < conta) then
                                -- memorizzazione "con shift"
                                o_mem_addr(i) <= addr(conta - 1 - i);
                            else
                            end if;
                        end loop;
                    end if;
                when READ_ADDR =>
                    -- solo logica applicativa, no delta
                    if i_start='1' then
                        -- autoanello
                        addr(conta) <= i_w;
                        conta <= conta + 1;
                    elsif i_start='0' then
                        -- uscita da autoanello
                        -- riempimento indirizzo con 0
                        o_mem_addr <= (others => '0');
                        
                        -- ciclo costante per sintesi
                        for i in 0 to 15 loop
                            if(i < conta) then
                                -- memorizzazione "con shift"
                                o_mem_addr(i) <= addr(conta - 1 - i);
                            else
                            end if;
                        end loop;
                    end if;
                when READ_AND_OUT =>
                    -- meccanismo di scelta
                    if choose(0) = '0' and choose(1) = '0' then
                        buff_z0 <= i_mem_data;
                        o_z0 <= i_mem_data;
                        o_z1 <= buff_z1;
                        o_z2 <= buff_z2;
                        o_z3 <= buff_z3;
                    elsif choose(0) = '0' and choose(1) = '1' then
                        buff_z1 <= i_mem_data;
                        o_z1 <= i_mem_data;
                        o_z0 <= buff_z0;
                        o_z2 <= buff_z2;
                        o_z3 <= buff_z3;
                    elsif choose(0) = '1' and choose(1) = '0' then
                        buff_z2 <= i_mem_data;
                        o_z2 <= i_mem_data;
                        o_z0 <= buff_z0;
                        o_z1 <= buff_z1;
                        o_z3 <= buff_z3;
                    elsif choose(0) = '1' and choose(1) = '1' then
                        buff_z3 <= i_mem_data;
                        o_z3 <= i_mem_data;
                        o_z0 <= buff_z0;
                        o_z1 <= buff_z1;
                        o_z2 <= buff_z2;
                    end if;
                    
                    -- done
                    o_done <= '1';
                when others =>
            end case;
        end if;
     end process;
end pf_arch;